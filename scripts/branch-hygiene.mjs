import { appendFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

// A squash merge need not preserve head SHA in the base's ancestry.
// Instead require GitHub's merged PR record AND an unchanged head.
export function candidate(branch, pulls, repository, defaultBranch) {
  const name = branch.name;
  if (branch.protected || [defaultBranch, 'main', 'dev'].includes(name) ||
      /^(release|hotfix|support|archive)(\/|$)/.test(name)) return null;
  const sameHead = pulls.filter(p => p.head?.repo?.full_name === repository && p.head.ref === name);
  if (sameHead.some(p => p.state === 'open')) return null;
  return sameHead.find(p => p.merged_at && p.state === 'closed' &&
    p.head.sha === branch.commit.sha && p.base?.repo?.full_name === repository &&
    ['dev', 'main'].includes(p.base.ref)) ?? null;
}

export function deletionArgs(branch) {
  const ref = `refs/heads/${branch.name}`;
  return ['push', `--force-with-lease=${ref}:${branch.commit.sha}`, 'origin', `:${ref}`];
}

export async function clean({ api, repository, apply = false, push, write = console.log }) {
  const repo = await api('');
  const branches = await api('/branches', true);
  const pulls = await api('/pulls?state=all', true);
  const results = [];
  for (const branch of branches) {
    const pr = candidate(branch, pulls, repository, repo.default_branch);
    if (!pr) continue;
    // Re-read both branch and all open PRs immediately before deletion.
    const latest = await api(`/branches/${encodeURIComponent(branch.name)}`);
    const open = await api('/pulls?state=open', true);
    if (!latest || latest.commit.sha !== branch.commit.sha || latest.protected ||
        !candidate(latest, [...open, pr], repository, repo.default_branch)) {
      results.push({ branch: branch.name, sha: branch.commit.sha, pr: pr.number, status: 'preserved-changed' });
      continue;
    }
    const merged = await api(`/pulls/${pr.number}`);
    if (!candidate(latest, [merged], repository, repo.default_branch)) {
      results.push({ branch: branch.name, sha: branch.commit.sha, pr: pr.number, status: 'preserved-changed' });
      continue;
    }
    let status = 'eligible';
    if (apply) {
      // Git enforces the expected SHA at the server, closing the race left by
      // an unconditional REST DELETE. Never retry a rejected lease.
      const result = push(deletionArgs(latest));
      if (result.status !== 0) throw new Error(`Deletion rejected for ${branch.name}; inspect before retrying`);
      status = 'deleted';
    }
    const item = { branch: branch.name, sha: branch.commit.sha, pr: pr.number, status };
    results.push(item);
    write(JSON.stringify(item));
  }
  return results;
}

async function main() {
  const repository = process.env.GITHUB_REPOSITORY;
  const token = process.env.GITHUB_TOKEN;
  if (!repository || !token) throw new Error('GITHUB_REPOSITORY and GITHUB_TOKEN are required');
  const root = `https://api.github.com/repos/${repository}`;
  const api = async (path, paginated = false) => {
    const all = [];
    for (let page = 1; ; page++) {
      const suffix = paginated ? `${path.includes('?') ? '&' : '?'}per_page=100&page=${page}` : '';
      const response = await fetch(`${root}${path}${suffix}`, {
        headers: { Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28' },
      });
      if (response.status === 404 && path.startsWith('/branches/')) return null;
      if (!response.ok) throw new Error(`GitHub returned ${response.status} for ${path}`);
      const data = await response.json();
      if (!paginated) return data;
      all.push(...data);
      if (data.length < 100) return all;
    }
  };
  const results = await clean({ api, repository, apply: process.argv.includes('--apply'),
    push: args => spawnSync('git', args, { stdio: 'inherit', shell: false }) });
  if (process.env.GITHUB_STEP_SUMMARY) {
    const lines = ['## Branch maintenance', '', ...results.map(r =>
      `- ${r.status}: \`${r.branch}\` (PR #${r.pr}, SHA \`${r.sha}\`)`)];
    if (!results.length) lines.push('No eligible merged branches.');
    appendFileSync(process.env.GITHUB_STEP_SUMMARY, lines.join('\n') + '\n');
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => { console.error(error.message); process.exitCode = 1; });
}

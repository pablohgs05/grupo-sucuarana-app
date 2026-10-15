import test from 'node:test';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { candidate, clean, deletionArgs } from '../branch-hygiene.mjs';
const repo = 'pablohgs05/grupo-sucuarana-app';
const sha = 'a'.repeat(40);
const branch = (name = 'feature/done') => ({ name, protected: false, commit: { sha } });
const pull = (extra = {}) => ({ number: 1, state: 'closed', merged_at: '2026-10-15',
  head: { ref: 'feature/done', sha, repo: { full_name: repo } },
  base: { ref: 'dev', repo: { full_name: repo } }, ...extra });
const eligible = (b, ps) => candidate(b, ps, repo, 'main');

test('accepts unchanged merged head, including squash merges', () => {
  assert.equal(eligible(branch(), [pull({ merge_commit_sha: 'b'.repeat(40) })]).number, 1);
});
for (const name of ['main', 'dev', 'release/1.0', 'hotfix/urgent', 'support/lts', 'archive/snapshot', 'custom-default']) {
  test(`preserves permanent branch ${name}`, () => {
    const p = pull(); p.head.ref = name;
    assert.equal(candidate(branch(name), [p], repo, 'custom-default'), null);
  });
}
test('preserves any protected branch', () => assert.equal(eligible({ ...branch(), protected: true }, [pull()]), null));
test('preserves new commits after merge', () => assert.equal(eligible({ ...branch(), commit: { sha: 'b'.repeat(40) } }, [pull()]), null));
test('preserves closed unmerged PR', () => assert.equal(eligible(branch(), [pull({ merged_at: null })]), null));
test('preserves branch with any open PR, including drafts', () => {
  assert.equal(eligible(branch(), [pull(), pull({ state: 'open', draft: true, merged_at: null })]), null);
});
test('preserves branch without PR', () => assert.equal(eligible(branch(), []), null));
test('ignores matching branch from fork', () => {
  const p = pull(); p.head.repo.full_name = 'someone/fork';
  assert.equal(eligible(branch(), [p]), null);
});
test('preserves unknown merge destination', () => {
  const p = pull(); p.base.ref = 'experimental';
  assert.equal(eligible(branch(), [p]), null);
});
test('deletion includes exact lease and uses full refs', () => {
  assert.deepEqual(deletionArgs(branch()), ['push', `--force-with-lease=refs/heads/feature/done:${sha}`, 'origin', ':refs/heads/feature/done']);
});

function harness({ latest = branch(), opens = [], merged = pull(), status = 0 } = {}) {
  const calls = [];
  const api = async path => {
    if (path === '') return { default_branch: 'main' };
    if (path === '/branches') return [branch()];
    if (path === '/pulls?state=all') return [pull()];
    if (path.startsWith('/branches/')) return latest;
    if (path === '/pulls?state=open') return opens;
    if (path === '/pulls/1') return merged;
    throw new Error(`Unexpected path ${path}`);
  };
  return { calls, options: { api, repository: repo, apply: true, write: () => {},
    push: args => { calls.push(args); return { status }; } } };
}
test('dry run never writes', async () => {
  const h = harness(); await clean({ ...h.options, apply: false }); assert.equal(h.calls.length, 0);
});
test('deletes only validated unchanged head', async () => {
  const h = harness(); const result = await clean(h.options);
  assert.equal(h.calls.length, 1); assert.equal(result[0].status, 'deleted');
});
test('preserves branch advanced after initial inventory', async () => {
  const h = harness({ latest: { ...branch(), commit: { sha: 'b'.repeat(40) } } });
  await clean(h.options); assert.equal(h.calls.length, 0);
});
test('preserves new open PR after initial inventory', async () => {
  const h = harness({ opens: [pull({ state: 'open', merged_at: null })] });
  await clean(h.options); assert.equal(h.calls.length, 0);
});
test('preserves newly protected branch', async () => {
  const h = harness({ latest: { ...branch(), protected: true } });
  await clean(h.options); assert.equal(h.calls.length, 0);
});
test('revalidates merged PR before deletion', async () => {
  const h = harness({ merged: pull({ merged_at: null }) });
  await clean(h.options); assert.equal(h.calls.length, 0);
});
test('rejected lease fails and is never retried', async () => {
  const h = harness({ status: 1 });
  await assert.rejects(clean(h.options), /Deletion rejected/); assert.equal(h.calls.length, 1);
});
test('API failure aborts without deleting', async () => {
  const h = harness(); h.options.api = async () => { throw new Error('403'); };
  await assert.rejects(clean(h.options), /403/); assert.equal(h.calls.length, 0);
});

test('branch already removed by native auto-delete is a safe no-op', async () => {
  const h = harness({ latest: null });
  await clean(h.options); assert.equal(h.calls.length, 0);
});

for (const advanced of [false, true]) {
  test(`real Git deletion ${advanced ? 'rejects a raced commit' : 'accepts the exact merged head'}`, () => {
    const dir = mkdtempSync(join(tmpdir(), 'sucuarana-lease-'));
    try {
      const remote = join(dir, 'remote.git');
      const work = join(dir, 'work');
      const git = (args, cwd = dir) => {
        const r = spawnSync('git', args, { cwd, encoding: 'utf8', shell: false });
        assert.equal(r.status, 0, r.stderr); return r.stdout.trim();
      };
      git(['init', '-q', '--bare', remote]);
      git(['init', '-q', '--initial-branch=main', work]);
      const commit = () => git(['-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
        '-c', 'commit.gpgsign=false', 'commit', '-q', '--allow-empty', '-m', 'synthetic test'], work);
      commit();
      git(['checkout', '-q', '-b', 'feature/done'], work);
      git(['remote', 'add', 'origin', remote], work);
      git(['push', '-q', 'origin', 'feature/done'], work);
      const expected = git(['rev-parse', 'HEAD'], work);
      if (advanced) { commit(); git(['push', '-q', 'origin', 'feature/done'], work); }
      const result = spawnSync('git', deletionArgs({ name: 'feature/done', commit: { sha: expected } }),
        { cwd: work, encoding: 'utf8', shell: false });
      assert.equal(result.status === 0, !advanced);
      const refs = git(['ls-remote', 'origin', 'refs/heads/feature/done'], work);
      assert.equal(refs.length > 0, advanced);
    } finally { rmSync(dir, { recursive: true, force: true }); }
  });
}

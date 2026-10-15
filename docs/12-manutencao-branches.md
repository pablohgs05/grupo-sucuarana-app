# Manutenção automática das branches

## Política

`main` e `dev` são permanentes. Abrir uma branch por tarefa, enviar PR para `dev`
e iniciar a tarefa seguinte a partir da `dev` atualizada. O merge não exige
aprovação humana na `dev`, mas exige os checks já definidos no repositório.

O GitHub já está configurado para excluir automaticamente a branch de origem
após merge. O histórico continua disponível pela PR; não é necessário manter uma
branch concluída como cópia do código.

## Limpeza complementar

O workflow **Branch maintenance** roda a cada push na `dev` e pode ser executado
manualmente selecionando `dev`. Ele só executa código integrado na branch
protegida. Não executa código de PR em contexto com permissão de escrita.

Uma branch só pode ser removida se:

- não for a branch padrão, `main`, `dev` ou uma branch protegida;
- não tiver prefixo reservado `release/`, `hotfix/`, `support/` ou `archive/`;
- não tiver nenhuma PR aberta neste repositório, incluindo rascunhos;
- corresponder ao SHA exato de uma PR mergeada em `main` ou `dev` neste repositório.

A branch e as PRs abertas são consultadas novamente antes da exclusão. O Git
confere o SHA esperado no servidor usando `--force-with-lease`: um commit novo
impede a exclusão, mesmo se chegar entre a conferência e o push. Não há exclusão
por idade, tentativa de adivinhar trabalho abandonado ou nova tentativa após
rejeição. Branch sem PR ou PR fechada sem merge é preservada.

O resultado registra nome, SHA e PR no resumo/log do workflow. Para conferir sem
excluir, usar `node scripts/branch-hygiene.mjs` com as variáveis `GITHUB_TOKEN` e
`GITHUB_REPOSITORY`. Apenas `--apply` permite exclusões.

## Testes obrigatórios

`node --test scripts/tests/*.test.mjs` roda dentro do check obrigatório mobile,
antes do Flutter, e novamente antes da manutenção. Inclui testes de política,
simulação de alterações concorrentes, falhas da API e testes reais com um remoto
Git temporário para provar que o SHA esperado permite exclusão e um SHA antigo a
bloqueia. Não requer serviços externos ou credenciais nos testes.

## Auditoria inicial (15/10/2026)

Foram identificadas 7 branches concluídas, sem commits posteriores às PRs:

| Branch | PR mergeada |
| --- | --- |
| `chore/flutter-ci` | #5 |
| `chore/repository-protection` | #8 |
| `feature/sqlite-local-store` | #4 |
| `fix/m10-offline-save-and-attachment-guards` | #53 |
| `fix/pdf-stress-typography-and-photos` | #52 |
| `pablohgs05-document-mvp-foundation` | #2 |
| `pablohgs05-run-project` | #3 |

A primeira execução da manutenção após integrar esta alteração deve limpar as
branches que ainda satisfaçam os critérios. Uma nova alteração ou PR aberta as
preserva automaticamente. Branches locais nos computadores não são apagadas;
`git fetch --prune` remove apenas referências remotas que já deixaram de existir.

# Contribuindo

## Antes de começar

Leia o [README](README.md), o [escopo](docs/01-visao-e-escopo.md) e a [arquitetura](docs/02-arquitetura.md). Não use o PDF real, fotos de operações ou qualquer dado pessoal em código, testes, screenshots ou issues.

## Fluxo de trabalho

1. Crie uma branch curta a partir de `main` (`feature/...`, `fix/...` ou `docs/...`).
2. Mantenha cada PR pequeno e com uma finalidade clara.
3. Atualize a documentação relacionada e inclua testes para comportamento novo.
4. Execute `scripts\verify.ps1` antes de abrir o PR.
5. Descreva no PR o problema, a solução, os riscos, os testes e eventuais migrações.

## Padrões

- Dart: `dart format` e lint do Flutter.
- Java: pacotes por responsabilidade, nomes em inglês e configuração por ambiente.
- Commits no imperativo, preferencialmente `feat:`, `fix:`, `docs:`, `test:` ou `chore:`.
- Nunca faça commit de `.env`, tokens, senhas, dumps, logs ou dados de campo.

## Revisão e pronto

Uma mudança só está pronta quando compila, tem teste proporcional, preserva o modo offline quando aplicável e foi revisada quanto a privacidade e segurança. O merge exige CI verde e aprovação de pelo menos uma pessoa responsável pelo projeto.

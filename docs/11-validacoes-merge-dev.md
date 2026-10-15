# Validações antes do merge em dev

## Verificações obrigatórias

A proteção da branch `dev`, conferida no GitHub em 15/10/2026, exige:

- **Analyze and test mobile app**: análise estática, todos os testes Flutter, cobertura mínima de 50% das linhas reportadas, validação do PDF fictício e compilação do APK Android debug.
- **Test backend**: `mvn --batch-mode verify`, testes HTTP e JaCoCo com mínimos de 80% de linhas e 80% de branches.
- **Analyze**: análise CodeQL do backend.

Também exige PR, branch atualizada com a base, resolução de conversas e histórico linear. Aprovação humana não é exigida na `dev`. Administradores estão sujeitos às proteções, e force push e exclusão estão bloqueados. `main` mantém aprovação humana.

O auto-merge é limitado a PRs não draft, originados no mesmo repositório e destinados à `dev`. A habilitação usa o SHA esperado e não ignora as proteções.

## Regressões adicionais

19 novos casos no backend cobrem campos ausentes, nulos e em branco, JSON e datas inválidos, consulta inexistente, isolamento de relatórios, reenvio idempotente e CORS.

6 novos testes Flutter cobrem contrato JSON, falhas de rede e servidor, rollback de gravações SQLite e migração de dados antigos corrompidos. Todos usam dados fictícios.

## Validação

Na PR #54, Flutter CI, Android Field Build, CodeQL e Dependency Review passaram. Isso inclui testes Flutter, análise estática, PDF, build Android e backend em Java 21. Localmente, os 21 testes backend passaram com 94,87% de cobertura de linhas e 100% de branches.

## CodeRabbit removido

O aplicativo CodeRabbit foi desinstalado da conta pablohgs05 e deixou de aparecer entre as integrações do repositório. A configuração `.coderabbit.yaml` foi removida após essa confirmação. Comentários históricos permanecem como registro das PRs.

## Limites

Testes reduzem regressões, mas não garantem ausência de defeitos. O backend atual continua sendo um protótipo com armazenamento em memória e endpoints de relatórios sem autenticação. A utilização com dados operacionais reais exige persistência em servidor e autorização, além de testes em dispositivos.

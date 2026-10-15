# Validações antes do merge em dev

O workflow Flutter CI mantém os nomes dos checks existentes:

- **Analyze and test mobile app**: análise estática, todos os testes Flutter,
  cobertura mínima de 50% das linhas reportadas pelo Flutter, validação do PDF
  fictício e compilação do APK Android debug. Uma falha em qualquer etapa reprova
  esse mesmo check; o build Android não depende apenas do workflow de artefatos.
- **Test backend**: `mvn --batch-mode verify`, testes HTTP e cobertura JaCoCo
  mínima de 80% de linhas e 80% de decisões (branches).

Testes adicionais cobrem campos ausentes/nulos/em branco, JSON e datas inválidos,
consulta inexistente, isolamento entre relatórios, reenvio idempotente,
restrição de origem CORS, contrato JSON do aplicativo, falhas de rede/servidor,
rollback de gravação SQLite e migração de dados legados corrompidos.
Todos os dados são fictícios.

## Proteção no GitHub

Os checks acima devem permanecer obrigatórios na proteção da branch `dev`,
com atualização em relação à base exigida. A configuração dos workflows não
substitui a configuração de branch protection. Não usar bypass de administrador.
O auto-merge continua limitado a PRs não draft, originados no mesmo repositório,
para `dev`, e só é habilitado para o SHA esperado. `main` mantém revisão humana.

Nesta revisão, a integração disponível retornou 403 ao consultar branch protection;
portanto, a obrigatoriedade dos checks não foi confirmada administrativamente.

## Remoção do revisor externo

A configuração `.coderabbit.yaml` atualmente desativa revisões automáticas.
Antes de excluir esse arquivo, remover o acesso do aplicativo CodeRabbit a este
repositório nas configurações de instalação do GitHub. Excluir apenas o arquivo
pode restaurar o comportamento padrão do aplicativo se ele continuar instalado.
A remoção da instalação não foi confirmada nesta revisão.

## Limites

Testes reduzem regressões, mas não garantem ausência de defeitos. O backend atual
continua sendo um protótipo com armazenamento em memória e endpoints de relatórios
sem autenticação. Estes testes não qualificam o backend para dados operacionais
reais nem substituem testes de dispositivo, persistência em servidor e autorização.

## Evidência local desta alteração

- 21 testes backend passaram, sem falhas ou erros, em Java 17 (disponível localmente).
- JaCoCo `report@coverage` e `check@coverage` passaram com os limites de 80%.
- O CI permanece configurado para Java 21; essa execução ainda precisa ocorrer.
- O empacotamento local não terminou por resolução de dependências do plugin JAR.
- Dart format e leitura sintática dos YAMLs passaram.
- Flutter e APK não foram executados: a revisão automática bloqueou o SDK ao
  detectar uma tentativa de acessar metadados do ambiente.
- Publicação da branch bloqueada pela revisão automática, pendente de autorização
  explícita para envio ao repositório pablohgs05/grupo-sucuarana-app.

Abrir inicialmente uma PR em rascunho para validar o CI completo, sem habilitar
merge de código ainda não verificado.

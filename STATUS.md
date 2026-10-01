# Status do projeto

**Atualizado em:** 2026-09-30  
**Fase:** MVP offline-first executável

## Entregue

- Monorepo com Flutter e Spring Boot.
- Fluxo Flutter estruturado para relatórios, persistência offline, anexos e exportação PDF.
- Contrato de sincronização idempotente entre app e API.
- Endpoint público `GET /api/health` e teste MVC.
- Configuração por variáveis de ambiente, exemplo sem segredo e MySQL opcional via Docker.
- Documentação de instalação, desenvolvimento, segurança/LGPD e roadmap.

## Ainda não implementado

Autenticação de usuários, armazenamento permanente de relatórios no servidor, migrations de produção e envio binário dos anexos. O servidor atual usa H2 em memória por padrão para facilitar o desenvolvimento local.

## Riscos e decisões pendentes

- Confirmar com o Grupo Suçuarana os campos obrigatórios, retenção e responsáveis pelo tratamento.
- Definir identidade visual e política de distribuição Android.
- Escolher estratégia de migrations antes de ativar o perfil MySQL em produção.

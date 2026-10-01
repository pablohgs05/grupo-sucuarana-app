# Backend

API REST Spring Boot responsável por autenticação, sincronização e consulta futura dos relatórios.

O backend ainda não contém regras de negócio. A base executável expõe `GET /api/health`, possui configuração de segurança mínima e teste MVC. A próxima entrega deve começar pelo contrato de sincronização, migrations e testes de idempotência.

Pacotes alvo:

```text
br.org.gruposucuarana
├── config
├── report
│   ├── controller
│   ├── domain
│   ├── repository
│   └── service
└── shared
```

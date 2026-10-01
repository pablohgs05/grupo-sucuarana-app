# Arquitetura

## Visão geral

```text
Tela Flutter
    ↓
Riverpod (estado e casos de uso)
    ↓
Repositórios
    ├── SQLite (fonte local durante o preenchimento)
    ├── Gerador PDF (execução local)
    └── Dio → API Spring Boot → MySQL
```

O app deve funcionar integralmente para criar, editar, fechar e exportar um relatório sem internet. A API é uma camada de sincronização e consulta, não um requisito para o fluxo principal em campo.

## Camadas do mobile

- `presentation`: telas, componentes e navegação.
- `application`: casos de uso e estado Riverpod.
- `domain`: entidades, enums e contratos de repositório.
- `data`: SQLite, DTOs, cliente Dio e sincronização.
- `services`: PDF, seleção de imagens e conectividade.

## Sincronização

Cada agregado local terá `local_id`, `remote_id`, `sync_status`, `updated_at` e `last_sync_error`.

Estados:

```text
PENDENTE → SINCRONIZANDO → SINCRONIZADO
                 └──────→ ERRO → PENDENTE
```

Regras:

1. Salvar no SQLite acontece antes de enfileirar sincronização.
2. Apenas um worker sincroniza o mesmo registro por vez.
3. Falhas transitórias usam novas tentativas com atraso progressivo.
4. O servidor aceita uma chave de idempotência por relatório.
5. Imagens são enviadas somente após os metadados do relatório serem aceitos.
6. O usuário pode tentar novamente manualmente e vê o erro em linguagem clara.

## Backend

O backend será stateless, exceto pelo banco, e organizado em `controller`, `service`, `repository`, `domain` e `config`. DTOs serão separados das entidades JPA. A autenticação JWT entra antes de expor dados reais de operações.


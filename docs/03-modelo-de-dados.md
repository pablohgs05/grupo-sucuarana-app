# Modelo inicial de dados

O modelo abaixo é uma referência para a implementação, não uma migração pronta.

## Report

| Campo | Tipo | Observação |
|---|---|---|
| `id` | UUID | Identificador local e remoto |
| `report_number` | string | Numeração legível, posterior |
| `operation_title` | string | Obrigatório |
| `bo_number` | string | Opcional conforme ocorrência |
| `operation_date` | date | Obrigatório |
| `city` | string | Obrigatório |
| `victim_data` | JSON/objeto | Dados pessoais da vítima |
| `occurrence_description` | text | Narrativa e horários |
| `coordinates` | JSON/objeto | Latitude, longitude e precisão |
| `teams` | JSON/objeto | Centro de comando e equipes |
| `resources` | JSON/objeto | Equipamentos e serviços usados |
| `conclusion` | text | Encerramento |
| `sync_status` | enum | Pendente, sincronizando, sincronizado ou erro |
| `created_at` / `updated_at` | datetime | Auditoria |

## Attachment

Um anexo deve guardar o caminho local, tipo MIME, tamanho, hash opcional, legenda e vínculo com o relatório. O arquivo físico permanece local até o upload ser confirmado.

## Segurança e retenção

Dados de vítima, documentos e imagens são sensíveis. O produto deve definir com a organização:

- quem pode acessar cada relatório;
- prazo de retenção e exclusão;
- backup e restauração;
- tratamento de aparelho perdido;
- necessidade de criptografia local e em trânsito.


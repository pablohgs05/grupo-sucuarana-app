# Roadmap

## Fundação

- [x] Monorepo e documentação inicial.
- [x] Shell Flutter executável com teste mínimo.
- [x] Backend executável com endpoint de saúde e teste.
- [x] Setup Windows, ambiente sem segredos e MySQL local opcional.
- [ ] Confirmar requisitos pendentes com o Grupo Suçuarana.
- [ ] Definir identidade visual e receber o logotipo oficial autorizado.
- [ ] Confirmar campos obrigatórios, regra de numeração e assinatura.

## MVP offline — marcos incrementais

- [x] **M0 — Especificação e roadmap:** escopo do MVP reconciliado a partir do material do cliente.
- [x] **M1 — Persistência local:** SQLite como fonte local de verdade.
- [x] **M2 — Rascunho e recuperação:** autosave, retomada e lifecycle local.
- [x] **M3 — Domínio de triagem:** modelo estruturado completo e compatibilidade com payload legado.
- [x] **M4 — Formulário de triagem:** wizard condicional e retomável.
- [x] **M5 — Seções operacionais:** narrativas, equipes, recursos e conclusão estruturados.
- [x] **M6 — Anexos persistentes:** cópia para armazenamento do app, legenda, ordem e remoção segura.
- [x] **M7 — Revisão:** conferência completa antes de `readyForReview`.
- [x] **M8 — PDF institucional:** capa, sumário, seções, triagem e anexos.
- [x] **M9 — Saída do PDF:** preview, compartilhamento e impressão.
- [ ] **M10 — Validação Android real offline:** executar e aprovar o checklist de campo no aparelho.
- [ ] **M11 — Decisão de backend/sync/backup:** reavaliar depois do M10; não faz parte do caminho crítico do MVP offline.

## Estado atual do M10

O código do fluxo offline até M9 já está integrado em `dev`. O M10 só pode ser
concluído após validação em aparelho Android real. O protocolo de teste está em
`docs/08-validacao-android-m10.md`.

Um workflow dedicado gera APK debug identificado pelo SHA para impedir que um
resultado de campo seja atribuído à build errada.

## Critério do MVP funcional

O MVP offline é considerado validado quando o M10 comprovar em Android real que
é possível, sem internet:

1. criar e retomar um relatório;
2. sobreviver a fechamento, force stop e reinicialização;
3. manter anexos persistentes;
4. revisar o conteúdo;
5. gerar e visualizar o PDF institucional;
6. entregar o PDF ao compartilhamento e ao framework de impressão do Android.

Backup contra perda/reset/desinstalação do aparelho não é garantido pelo
armazenamento local e deve ser decidido no M11.

## Próximas decisões do cliente

Continuam abertas:

- campos obrigatórios, opcionais e condicionais definitivos;
- regra institucional de numeração;
- identificação/cargo/assinatura de quem preenche;
- logotipo oficial e identidade visual final;
- necessidade e política de backup/sincronização.

## Evoluções posteriores

- histórico e busca local;
- cadastro de membros e seleção de equipes;
- GPS automático e checklist de recursos;
- numeração automática após regra institucional confirmada;
- fila de sincronização observável, se M11 aprovar sincronização;
- login e perfis, se houver backend;
- mapa da área de busca;
- assinatura digital;
- painel web e relatórios administrativos.

## Princípio de priorização

Priorizar segurança e preservação de dados, depois fluxo offline, depois entrega
do relatório. Nenhuma funcionalidade crítica do MVP deve exigir conectividade
para salvar, recuperar, revisar ou gerar o documento.

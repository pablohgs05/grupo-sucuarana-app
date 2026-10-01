# Segurança e LGPD

Este produto pode tratar dados pessoais e informações sensíveis de vítimas, equipes e localização. A documentação não substitui orientação jurídica; a organização deve confirmar controlador, operador, bases legais, retenção e canal de atendimento.

## Regras obrigatórias

- Coletar somente o mínimo necessário para a finalidade do relatório.
- Manter dados e fotos no dispositivo até uma sincronização autorizada e explícita.
- Criptografar dados em repouso e em trânsito antes da primeira distribuição de produção.
- Não registrar dados pessoais em logs, analytics, screenshots, fixtures ou mensagens de erro.
- Usar contas individuais, menor privilégio, rotação de credenciais e segredos fora do Git.
- Definir retenção, eliminação, exportação e resposta a incidentes com a organização.
- Fazer backup e restauração testados; acesso administrativo deve ser auditável.

## Checklist antes de produção

- [ ] DPIA/avaliação de impacto e inventário de dados aprovados.
- [ ] Política de privacidade e consentimentos revisados.
- [ ] Modelo de ameaça e revisão de dependências concluídos.
- [ ] Autenticação, autorização e rate limiting implementados.
- [ ] Banco com migrations, backups e acesso de rede restrito.
- [ ] Fluxo de apagamento e atendimento ao titular testado.

O endpoint de saúde é deliberadamente limitado a status técnico e não deve expor banco, ambiente, versão detalhada ou dados operacionais.

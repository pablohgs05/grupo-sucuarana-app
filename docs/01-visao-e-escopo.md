# Visão e escopo do MVP

## Problema

Os relatórios de operações são montados manualmente em um computador, o que atrasa o fechamento da ocorrência. Em campo, os voluntários precisam registrar informações, coordenadas e imagens usando o celular, inclusive sem conexão.

## Usuários

Voluntários com diferentes níveis de familiaridade com tecnologia, predominantemente usando Android. A aplicação deve privilegiar linguagem direta, botões grandes, progresso visível e recuperação de rascunhos.

## Relatório

O MVP contempla:

1. Capa: operação, BO, data, cidade e identificação do grupo.
2. Informações gerais da vítima.
3. Descrição da ocorrência, datas, horários e coordenadas.
4. Desenvolvimento e equipes.
5. Recursos utilizados.
6. Conclusão.
7. Anexos de imagens.
8. Geração, visualização e compartilhamento de PDF.

Assinatura gov.br, autenticação de usuários e sincronização em nuvem são posteriores. O PDF gerado localmente não deve depender do backend.

## Fora do MVP

- Painel web.
- Mapa interativo.
- Cadastro administrativo de membros.
- Assinatura digital integrada.
- Edição colaborativa simultânea.

## Critérios de aceite do MVP

- É possível criar e salvar um relatório sem internet.
- Fechar e reabrir o aplicativo não perde dados salvos.
- Fotos selecionadas ficam vinculadas ao relatório.
- O PDF pode ser visualizado e compartilhado pelo sistema operacional.
- Campos obrigatórios impedem o fechamento incompleto e informam como corrigir.


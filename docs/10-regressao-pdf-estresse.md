# Regressões de PDF em testes de estresse

Este documento descreve as correções propostas após análise de um PDF longo
gerado em Android. **Não versionar PDFs, fotos, nomes, documentos ou dados
operacionais de testes de campo**. O teste automatizado utiliza apenas dados
sintéticos.

## Fonte dos problemas

- Texto arbitrário com pontuação fora de WinAnsi aparecia com glifos ilegíveis
  ao utilizar as fontes PDF Helvetica embutidas.
- Narrativas extensas podiam terminar em uma palavra isolada na página seguinte.
- A última equipe de uma lista curta podia ficar sozinha na página posterior.
- Fotografias de alta resolução eram incorporadas sem otimização ao PDF.

## Mudanças

1. O conteúdo é preservado integralmente no relatório/SQLite. Apenas a
   representação PDF substitui pontuação incompatível por ASCII legível.
   Símbolos não mapeados tornam-se marcadores explícitos como `[U+1F47D]`,
   em vez de desaparecer. Isso não substitui uma futura fonte Unicode
   offline, caso o cliente necessite renderização visual fiel de emojis.
2. As narrativas são segmentadas em blocos curtos, mantidos juntos quando
   uma quebra de página ocorre. Blocos respeitam os parágrafos originais.
3. Listas pequenas de equipes passam a ser mantidas juntas; listas grandes
   continuam permitindo paginação.
4. Ao adicionar imagens, o seletor solicita dimensões de até 1800 × 1800 px
   e qualidade 80. As cópias armazenadas pelo app são independentes da foto
   original da galeria.
5. Fotos grandes já existentes são redimensionadas/comprimidas na geração
   do PDF em um isolate, sem alterar o anexo persistido. PNG com canal alfa
   conserva a transparência quando reprocessado; imagens pequenas não
   sofrem recompressão.

## Restrições e testes

- Otimizar imagens envolve um custo temporário de memória durante o decode;
  não garante funcionamento com qualquer volume de fotos/qualquer Android.
- Não alterar regras de obrigatoriedade, números, signatures ou dados
  fornecidos pelo cliente.
- `flutter test --coverage`, `flutter analyze` e a validação página a
  página do PDF devem passar.
- Testar novamente com APK da PR, relatório fictício longo e fotos sintéticas.
  Verificar legibilidade, paginação, tempo de geração, consumo de memória e
  funcionamento offline.
- A checklist real de force stop, reinicialização e preservação dos anexos
  permanece no M10.

## Segurança

Não ativar sincronização para dados reais. O backend de demonstração ainda
exige autenticação, autorização e persistência adequada antes da produção.

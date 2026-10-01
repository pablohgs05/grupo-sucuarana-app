# Guia de desenvolvimento

## Convenções

- Commits pequenos e em português ou inglês consistente, no imperativo.
- Branches: `main`, `develop` (se necessário) e `feature/nome-curto`.
- Pull requests devem explicar o comportamento alterado e como validar.
- Não versionar `.env`, chaves JWT, dumps ou fotos reais de operações.
- Dados de teste devem ser fictícios.

## Fluxo recomendado

1. Criar ou atualizar a documentação da decisão.
2. Implementar o caso de uso no domínio.
3. Adicionar persistência local e testes.
4. Conectar a tela.
5. Testar com modo avião.
6. Validar geração e compartilhamento do PDF em Android real.

## Qualidade mínima

Antes de abrir um PR:

```bash
cd app-mobile
dart format .
flutter analyze
flutter test

cd ../backend
./mvnw test
```

Não usar dados reais nos testes automatizados nem em screenshots.


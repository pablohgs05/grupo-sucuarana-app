# App mobile

Aplicativo Flutter para criação de relatórios offline-first.

O MVP permite criar e editar relatórios estruturados em seções de identificação,
desaparecido, operação, descrição física, vestimentas, saúde, procedimentos,
equipes, recursos, conclusão e anexos. Os relatórios são persistidos localmente
em SQLite, ficam identificados como pendentes/sincronizados e podem ser
exportados em PDF. A seleção de imagens usa `image_picker`; em ambientes web ou
sem suporte nativo, o app informa a limitação sem interromper o preenchimento.

Instalações que ainda tenham relatórios no armazenamento legado de
`shared_preferences` são migradas para SQLite na primeira abertura. A chave
legada é preservada após a migração para evitar exclusão silenciosa de dados;
SQLite passa a ser a fonte local de verdade.

Esta pasta já contém uma base Flutter executável, com `lib/main.dart` e testes
de widget/persistência. As funcionalidades de negócio serão adicionadas
incrementalmente, sem quebrar a organização abaixo.

Estrutura alvo:

```text
lib/
├── app/
├── core/
├── features/
│   └── reports/
│       ├── data/
│       ├── domain/
│       ├── application/
│       └── presentation/
└── main.dart
```

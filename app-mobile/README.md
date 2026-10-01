# App mobile

Aplicativo Flutter para criação de relatórios offline-first.

O MVP permite criar e editar relatórios estruturados em seções de identificação,
desaparecido, operação, descrição física, vestimentas, saúde, procedimentos,
equipes, recursos, conclusão e anexos. Os dados são persistidos no dispositivo
com `shared_preferences`, ficam identificados como pendentes/sincronizados e
podem ser exportados em PDF. A seleção de imagens usa `image_picker`; em
ambientes web ou sem suporte nativo, o app informa a limitação sem interromper
o preenchimento.

Esta pasta já contém uma base Flutter executável, com `lib/main.dart` e um teste de widget. As funcionalidades de negócio serão adicionadas incrementalmente, sem quebrar a organização abaixo.

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

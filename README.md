# Grupo Suçuarana — Relatórios de Operação

Aplicativo offline-first para preenchimento de relatórios de operações socioambientais do Grupo Suçuarana, com exportação para PDF e sincronização posterior com a API.

O projeto é voluntário e está sendo desenvolvido com foco em simplicidade, confiabilidade em campo e facilidade de manutenção por uma equipe pequena.

## Estrutura

```text
.
├── app-mobile/    # Aplicativo Flutter/Dart para Android
├── backend/       # API REST Spring Boot/Java
└── docs/          # Arquitetura, decisões e planejamento
```

## Stack

| Camada | Tecnologia |
|---|---|
| Mobile | Flutter, Dart, Riverpod |
| Persistência local | SQLite |
| Comunicação | Dio, API REST |
| PDF | `pdf`, `printing` |
| Fotos e conectividade | `image_picker`, `connectivity_plus` |
| Backend | Java, Spring Boot, Spring Data JPA |
| Segurança | Spring Security + JWT |
| Banco remoto | MySQL |
| Documentação da API | OpenAPI/Swagger |

## Princípios do MVP

- **Offline-first:** o preenchimento não depende de internet.
- **Persistência antes de sincronização:** um relatório é salvo localmente antes de qualquer chamada de rede.
- **Sincronização idempotente:** o mesmo relatório pode ser reenviado sem criar duplicatas.
- **Interface simples:** poucos passos, textos claros e validação próxima do campo.
- **Privacidade:** dados de vítimas e fotos não devem ser enviados para serviços externos não autorizados.

## Começando

### Pré-requisitos

- Flutter stable e Dart compatíveis com o SDK definido em `app-mobile/pubspec.yaml`
- Java 21 e Maven 3.9+ (ou Maven Wrapper)
- MySQL 8+ para o ambiente de backend

### Mobile

```bash
cd app-mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

### Backend

```bash
cd backend
./mvnw spring-boot:run
```

No Windows, use `mvnw.cmd spring-boot:run`.

O backend inicial sobe com endpoints de saúde e documentação habilitáveis conforme a implementação das próximas etapas. Configurações locais devem ser feitas por variáveis de ambiente; nunca com credenciais versionadas.

## Documentação

- [Visão e escopo do MVP](docs/01-visao-e-escopo.md)
- [Arquitetura offline-first](docs/02-arquitetura.md)
- [Modelo inicial de dados](docs/03-modelo-de-dados.md)
- [Guia de desenvolvimento](docs/04-desenvolvimento.md)
- [Roadmap](docs/05-roadmap.md)

## Status

Fase de fundação: estrutura inicial e decisões arquiteturais. Ainda não há funcionalidades de negócio implementadas.

## Licença

Projeto desenvolvido para uso social e voluntário pelo Grupo Suçuarana. A licença e as regras de distribuição devem ser confirmadas com a organização antes da primeira publicação.


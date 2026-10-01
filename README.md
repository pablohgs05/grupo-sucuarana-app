# Grupo Suçuarana — Relatórios de Operação

Aplicativo offline-first para preenchimento de relatórios de operações socioambientais, com persistência local, exportação para PDF e sincronização posterior com a API. O projeto é voluntário, com foco em confiabilidade em campo, privacidade e manutenção por uma equipe pequena.

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

## Começando no Windows

### Pré-requisitos

- Git, Flutter stable/Dart, Android Studio com SDK e emulador, JDK 21 e Maven 3.9+.
- Docker Desktop é opcional e usado somente para o MySQL local.

O passo a passo de instalação do Flutter, Android Studio, Java, Maven e MySQL está em [docs/06-setup-windows.md](docs/06-setup-windows.md).

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
cd ..
docker compose up -d mysql # opcional
cd backend
mvn spring-boot:run
```

No Windows, use `mvnw.cmd` se o Maven Wrapper estiver disponível. O backend expõe `GET http://localhost:8080/api/health` sem autenticação e `POST /api/reports/sync` para sincronizar relatórios de forma idempotente. Por padrão ele usa H2 em memória, então funciona sem Docker; para persistência MySQL, defina `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` e `DB_PLATFORM=org.hibernate.dialect.MySQLDialect`.

Para preparar o ambiente, copie `.env.example` para `.env` e ajuste apenas localmente. Nunca versione credenciais.

Verificação completa:

```powershell
.\scripts\verify.ps1
```

## Documentação

- [Visão e escopo do MVP](docs/01-visao-e-escopo.md)
- [Arquitetura offline-first](docs/02-arquitetura.md)
- [Modelo inicial de dados](docs/03-modelo-de-dados.md)
- [Guia de desenvolvimento](docs/04-desenvolvimento.md)
- [Roadmap](docs/05-roadmap.md)
- [Setup detalhado no Windows](docs/06-setup-windows.md)
- [Segurança e LGPD](docs/07-seguranca-lgpd.md)
- [Contribuição](CONTRIBUTING.md)
- [Status atual](STATUS.md)
- [Changelog](CHANGELOG.md)

## Status

Fase de fundação executável: o shell Flutter, o endpoint de saúde e os testes mínimos estão prontos. Persistência, formulário, PDF, sincronização e autenticação continuam fora desta etapa. Consulte [STATUS.md](STATUS.md) e o [roadmap](docs/05-roadmap.md).

## Critérios de pronto do MVP

O MVP será considerado pronto quando uma pessoa autorizada conseguir criar e revisar um relatório sem internet, salvar rascunhos e anexos localmente, gerar/compartilhar o PDF, sincronizar de forma idempotente quando houver conexão e recuperar o trabalho após falhas. Isso deve estar coberto por testes automatizados, teste em Android físico, revisão de segurança/LGPD e documentação de operação.

## Licença

Projeto desenvolvido para uso social e voluntário pelo Grupo Suçuarana. A licença e as regras de distribuição devem ser confirmadas com a organização antes da primeira publicação.

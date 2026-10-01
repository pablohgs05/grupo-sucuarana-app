# Setup no Windows

## Pré-requisitos

1. Instale o [Git para Windows](https://git-scm.com/download/win) e reinicie o terminal.
2. Instale o [Flutter stable](https://docs.flutter.dev/get-started/install/windows), adicione `flutter\bin` ao `PATH` e valide com `flutter doctor`.
3. Instale o [Android Studio](https://developer.android.com/studio), o Android SDK, Platform-Tools, uma imagem de emulador e aceite as licenças com `flutter doctor --android-licenses`.
4. Instale o [JDK 21](https://adoptium.net/) e configure `JAVA_HOME`; valide com `java -version`.
5. Instale o [Maven 3.9+](https://maven.apache.org/download.cgi) ou use o Maven Wrapper quando ele for adicionado ao backend.
6. Instale o [Docker Desktop](https://www.docker.com/products/docker-desktop/) apenas se quiser executar MySQL localmente.

## Clonar e preparar

```powershell
git clone https://github.com/pablohgs05/grupo-sucuarana-app.git
cd grupo-sucuarana-app
Copy-Item .env.example .env
.\scripts\setup.ps1
```

O `.env` é apenas uma referência local. Troque todos os valores antes de usar um banco real e nunca o envie ao Git.

## Executar o mobile

```powershell
cd app-mobile
flutter devices
flutter run
```

Para validar sem dispositivo, use `flutter analyze` e `flutter test`.

## Executar o backend

```powershell
docker compose up -d mysql
cd backend
mvn spring-boot:run
```

Teste `http://localhost:8080/api/health`. Swagger fica em `http://localhost:8080/swagger-ui.html`. Como ainda não há migrations nem entidades, a conexão com MySQL só deve ser usada quando o schema correspondente existir.

## Problemas comuns

- `flutter doctor` com licenças pendentes: execute `flutter doctor --android-licenses` em um terminal com o SDK correto.
- `JAVA_HOME` incorreto: aponte para a pasta do JDK, não para `bin`, e abra um novo terminal.
- Emulador lento: habilite virtualização no BIOS/Windows e prefira um dispositivo físico para teste de campo.
- Porta 3306 ocupada: altere o mapeamento no `docker-compose.yml` e o `DB_URL`.
- PowerShell bloqueando scripts: use `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` conforme a política da máquina.

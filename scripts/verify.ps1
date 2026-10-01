$ErrorActionPreference = "Stop"

Push-Location "$PSScriptRoot\..\app-mobile"
flutter analyze
flutter test
Pop-Location

Push-Location "$PSScriptRoot\..\backend"
if (Test-Path ".\mvnw.cmd") {
    .\mvnw.cmd test
} else {
    mvn test
}
Pop-Location

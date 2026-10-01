$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter não encontrado no PATH. Consulte docs/06-setup-windows.md."
}
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw "Java não encontrado no PATH. Consulte docs/06-setup-windows.md."
}

Push-Location "$PSScriptRoot\..\app-mobile"
flutter pub get
Pop-Location

Write-Host "Dependências do mobile instaladas. O banco MySQL é opcional; use docker compose up -d mysql."

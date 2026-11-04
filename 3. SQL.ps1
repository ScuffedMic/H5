
# ==========================================
# SQL SERVER LAB - SAMLET INSTALLATION
# ==========================================

# Krav: Kør PowerShell som administrator

$ErrorActionPreference = "Stop"

# KONFIGURATION
$ServerName = "LOKI-APP1"
$DomainGroup = "LOKI\SG_IT_RW"
$Setup = "C:\Users\bobbi\Downloads\SQL2022-SSEI-Expr.exe"

Write-Host "Starter SQL Server lab-konfiguration..." -ForegroundColor Cyan

# ==========================================
# 1. OPRET SQL MAPPER
# ==========================================

Write-Host "`n[1/7] Opretter SQL mapper..."

$Folders = @(
    "E:\SQL\Data",
    "E:\SQL\Logs",
    "E:\SQL\Backup"
)

foreach ($Folder in $Folders) {
    New-Item -Path $Folder -ItemType Directory -Force | Out-Null
}

Write-Host "SQL mapper oprettet." -ForegroundColor Green

# ==========================================
# 2. START SQL SERVER INSTALLATION
# ==========================================

Write-Host "`n[2/7] Starter SQL Server installation..."

if (-not (Test-Path $Setup)) {
    throw "Installationsfilen blev ikke fundet: $Setup"
}

$Process = Start-Process `
    -FilePath $Setup `
    -Wait `
    -PassThru

Write-Host "Installationsprogram afsluttet med exit code: $($Process.ExitCode)"

if ($Process.ExitCode -ne 0) {
    throw "SQL Server installationsprogrammet returnerede en fejl."
}

Write-Host "Kontroller, at SQL Server er installeret færdigt, før du fortsætter." -ForegroundColor Yellow

# ==========================================
# 3. KONTROLLER SQL SERVER SERVICES
# ==========================================

Write-Host "`n[3/7] Kontrollerer SQL Server services..."

$SqlService = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue

if (-not $SqlService) {
    Write-Warning "SQL Server Database Engine er ikke fundet."
    Write-Warning "Hvis du har installeret Express, kan servicen hedde MSSQL$SQLEXPRESS."
    throw "SQL Server installation skal færdiggøres først."
}

if ($SqlService.Status -ne "Running") {
    Start-Service -Name "MSSQLSERVER"
}

Write-Host "SQL Server service kører." -ForegroundColor Green

# ==========================================
# 4. OPRET FIREWALL REGEL
# ==========================================

Write-Host "`n[4/7] Konfigurerer firewall..."

$ExistingRule = Get-NetFirewallRule `
    -DisplayName "SQL Server TCP 1433" `
    -ErrorAction SilentlyContinue

if (-not $ExistingRule) {
    New-NetFirewallRule `
        -DisplayName "SQL Server TCP 1433" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 1433 `
        -Action Allow `
        -Profile Domain
}

Write-Host "Firewall regel oprettet." -ForegroundColor Green

# ==========================================
# 5. INSTALLER SSMS
# ==========================================

Write-Host "`n[5/7] Installerer SSMS..."

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id Microsoft.SQLServerManagementStudio `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "SSMS installation fejlede."
    }
}
else {
    Write-Warning "WinGet blev ikke fundet. Installer SSMS manuelt."
}

Write-Host "SSMS installationsforsøg afsluttet." -ForegroundColor Green

# ==========================================
# 6. INSTALLER SQLSERVER POWERSHELL MODUL
# ==========================================

Write-Host "`n[6/7] Installerer SQLServer PowerShell modul..."

if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Install-Module SqlServer -Scope AllUsers -Force -AllowClobber
}

Import-Module SqlServer

Write-Host "SqlServer modul klar." -ForegroundColor Green

# ==========================================
# 7. OPRET AD LOGIN I SQL SERVER
# ==========================================

Write-Host "`n[7/7] Opretter AD login i SQL Server..."

$Query = @"
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE name = '$DomainGroup'
)
BEGIN
    CREATE LOGIN [$DomainGroup] FROM WINDOWS;
END;
"@

Invoke-Sqlcmd `
    -ServerInstance $ServerName `
    -Query $Query `
    -ErrorAction Stop

Write-Host "AD gruppen er oprettet som SQL Server login." -ForegroundColor Green

# ==========================================
# AFSLUTNING
# ==========================================

Write-Host "`n==================================" -ForegroundColor Cyan
Write-Host "SQL SERVER LAB SCRIPT GENNEMFØRT" -ForegroundColor Green
Write-Host "Server: $ServerName"
Write-Host "AD gruppe: $DomainGroup"
Write-Host "==================================" -ForegroundColor Cyan

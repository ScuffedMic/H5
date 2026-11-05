[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [Parameter()]
    [string]$SiteName = "Default-First-Site-Name",

    [Parameter()]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter()]
    [string]$PreferredDnsServer = "192.168.99.30",

    [Parameter()]
    [string]$AlternateDnsServer = "192.168.99.31",

    [Parameter()]
    [switch]$SkipDnsConfig,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [System.ConsoleColor]::Cyan
    )

    Write-Host "" 
    Write-Host "[STEP] $Message" -ForegroundColor $Color
}

function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AdapterForDnsConfig {
    $adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Sort-Object InterfaceIndex | Select-Object -First 1
    if (-not $adapter) {
        $adapter = Get-NetAdapter | Sort-Object InterfaceIndex | Select-Object -First 1
    }

    if (-not $adapter) {
        throw "Kunne ikke finde en netadapter på serveren. Tjek netværkskonfigurationen."
    }

    return $adapter
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Global Catalog DC replacement - prep + promote ny DC" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Formål: Forberede en ny DC, aktivere Global Catalog og gøre den klar til at overtage rollen."
Write-Host "" 

if (-not (Test-IsAdmin)) {
    throw "Scriptet skal køres som Administrator."
}

if (-not $Credential) {
    $Credential = Get-Credential -Message "Angiv domænekonto med rettigheder til at promovere en ny DC i $DomainName"
}

if (-not $DomainName) {
    throw "Du skal angive -DomainName, fx 'contoso.local'."
}

$computerDomain = (Get-CimInstance Win32_ComputerSystem).Domain
if (-not $computerDomain) {
    throw "Serveren er ikke medlem af et domæne. Join den først til $DomainName, før du kører scriptet."
}

if ($computerDomain -ne $DomainName) {
    throw "Denne server er ikke medlem af domænet $DomainName. Den er medlem af $computerDomain."
}

Write-Step "Installerer AD-Domain-Services og DNS" -Color Yellow
Install-WindowsFeature -Name AD-Domain-Services,DNS -IncludeManagementTools -IncludeAllSubFeature

if (-not $SkipDnsConfig) {
    Write-Step "Konfigurerer DNS-serveradresser på den aktive netadapter" -Color Yellow
    $adapter = Get-AdapterForDnsConfig
    try {
        Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses @($PreferredDnsServer, $AlternateDnsServer) -ErrorAction Stop
        Write-Host "DNS er sat til: $PreferredDnsServer, $AlternateDnsServer" -ForegroundColor Green
    }
    catch {
        Write-Warning "Kunne ikke konfigurere DNS-adressen automatisk. Tjek netadapteren manuelt: $($adapter.Name)"
    }
}

Write-Step "Validerer at AD DS er installeret korrekt" -Color Yellow
$feature = Get-WindowsFeature -Name AD-Domain-Services
if ($feature.Installed -ne $true) {
    throw "AD-Domain-Services blev ikke installeret korrekt."
}

Write-Step "Promoverer serveren som ny DC og aktiverer Global Catalog" -Color Yellow
$securePassword = Read-Host "Angiv Safe Mode Administrator password" -AsSecureString

try {
    Install-ADDSDomainController `
        -DomainName $DomainName `
        -InstallDns `
        -Credential $Credential `
        -SafeModeAdministratorPassword $securePassword `
        -SiteName $SiteName `
        -NoGlobalCatalog:$false `
        -Force:$Force
}
catch {
    Write-Error "Promovering af ny DC mislykkedes: $($_.Exception.Message)"
    throw
}

Write-Step "Verificerer status for Global Catalog" -Color Green
$dc = Get-ADDomainController -Identity $env:COMPUTERNAME -ErrorAction Stop

if ($dc.IsGlobalCatalog -ne $true) {
    Write-Warning "Serveren er ikke markeret som Global Catalog. Sætter den manuelt ..."
    Set-ADDomainController -Identity $env:COMPUTERNAME -IsGlobalCatalog $true
}

Write-Host "OK: $env:COMPUTERNAME er nu Global Catalog Domain Controller." -ForegroundColor Green
Write-Host "" 
Write-Host "Status: Ny DC er klar til at overtage rollen som GC." -ForegroundColor Green
Write-Host "" 
Write-Host "Anbefalet næste trin:" -ForegroundColor Yellow
Write-Host "1. Verificer replikation og AD-health på den gamle DC." -ForegroundColor Yellow
Write-Host "2. Flyt GC-funktionen fra gammel server til ny server, hvis det ønskes." -ForegroundColor Yellow
Write-Host "3. Demote den gamle DC først når alt er stabilt." -ForegroundColor Yellow
Write-Host "" 
Write-Host "Eksempel på GC-overførsel:" -ForegroundColor Yellow
Write-Host "Set-ADDomainController -Identity <GammelDC> -IsGlobalCatalog:`$false" -ForegroundColor Gray
Write-Host "Set-ADDomainController -Identity $env:COMPUTERNAME -IsGlobalCatalog:`$true" -ForegroundColor Gray

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Færdig." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

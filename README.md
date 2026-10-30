# H5 - IT-opgavepakke

Dette repository indeholder scripts og dokumentation til en H5-opgavepakke inden for Windows Server / Active Directory / DHCP / SQL / overvågning / share-sikkerhed.

Repositoryt er struktureret omkring fem konkrete opgaver, som beskriver typiske incident-, ændrings- og requests-for-change-scenarier i en organisation.

## Opgaveoversigt

### 1. Incident: Global Catalog Domain Controller skal udskiftes

Scenario:
- En Global Catalog Domain Controller fejler eller skal erstattes.
- Den nye server skal forberedes, så den er klar til at overtage rollen.

Formål:
- Forberede den nye DC til AD-roller.
- Sætte serveren op med korrekt AD-tilslutning og GC-rolle.
- Sikre, at den kan tage over uden driftssvigt.

Kontrolpunkter:
- DNS er korrekt konfigureret.
- Serveren er medlem af domænet.
- AD-roller installeres i den rigtige rækkefølge.
- Replikering verificeres.

### 2. Incident: BYOD adgangfejl pga. DHCP-scope / lease

Scenario:
- Enheder på netværket kan ikke få adgang via BYOD på grund af for lille DHCP-scope eller for lang lease-tid.

Formål:
- Øge antallet af ledige IP-adresser i DHCP-scopet.
- Justere lease-duration, så større mobilitetsbehov håndteres bedre.

Typiske handlinger:
- Gennemgå DHCP-scope størrelse.
- Udvide start-/slut-range eller oprette nye scopes.
- Justere lease-duration til en mere passende værdi.
- Verificere, at nye adresser bliver tildelt korrekt.

### 3. Ny Application Server med MS SQL Server Enterprise Edition

Scenario:
- En afdeling ønsker en ny Application Server med SQL Server Enterprise Edition.
- Serveren skal konfigureres, så en OU i organisationen får adgang via SSMS.
- Services skal køre under SA-kontoen.

Formål:
- Installere og konfigurere SQL Server.
- Sikre adgang til den relevante afdeling / OU.
- Korrekt serviceidentitet og sikkerhedskonfiguration.

Vigtige elementer:
- Windows Server-opstilling.
- SQL Server installation.
- Legitimations- og sikkerhedskonfiguration.
- SSMS-driftssikkerhed og brugeradgang.

### 4. Application Server skal sende events til overvågning

Scenario:
- En Application Server skal have event-log eller overvågningsfunktioner aktiveret.
- Serveren skal være valgt til at passe til organisationens infrastruktur.
- Events skal håndteres korrekt i sagshåndtering.

Formål:
- Sørge for, at relevante Windows events bliver logget og kan overvåges.
- Integrere med organisations overvågnings- eller incidentflow.
- Gøre eventdata anvendelige i en sag.

### 5. Request For Change: Sharing / mappe med begrænset adgang

Scenario:
- En eksisterende share skal ændres, så kun administrationen har adgang.
- IT-afdelingen må ikke kunne tilgå indholdet af mappen.
- En OU skal have adgang, mens en anden OU skal være uden adgang.

Formål:
- Sikre korrekt NTFS- og share-tilladelser.
- Reducere risiko for uautoriseret adgang.
- Gøre mappen robust over for fejl, sletninger eller datatab.

Datagendannelse:
- Backup / snapshots / versioning.
- Korrekt permissions-model.
- Nåletråd på sikkerhed, ansvar og genskabelse.

## Scripts i repository

Dette repository indeholder i øjeblikket følgende PowerShell-script:

### changeDHCP

Dette script justerer DHCP-scopeets lease-duration og adresseområde, så der bliver flere ledige IP-adresser til rådighed.

Eksempel på funktionalitet:
- $ScopeId
- $LeaseDuration
- $Startrange
- $EndRange

Scriptet bruger cmdlet'en:
- Set-DhcpServer4Scope

Det er relevant i forbindelse med opgave 2, hvor DHCP-scopet skal udvides eller justeres for at håndtere BYOD-adgang.

## Eksempel på brug

```powershell
$ScopeId = "10.0.0.0"
$LeaseDuration = "08:00:00"
$Startrange = "10.0.0.100"
$EndRange = "10.0.0.200"

Set-DhcpServer4Scope -ScopeId $ScopeId -LeaseDuration $LeaseDuration
Set-DhcpServer4Scope -ScopeId $ScopeId -StartRange $Startrange -EndRange $EndRange
```

## Praktisk formål med repoet

Repositoryt fungerer som et opslagsværk og en arbejdsbase for løsning af de fem H5-opgaver. Det er målrettet mod:
- Windows Server administration
- Active Directory / Global Catalog
- DHCP / netværksadgang
- SQL Server installation og konfiguration
- Overvågning / event logs
- Sikkerhed / tilgange / shares

## Bemærkning

Dette repo kan udvides med flere PowerShell-scripts eller dokumentationsfiler for hver enkelt opgave, så hver incident, ændring og request for change bliver dokumenteret separat.

---

H5 - IT Automation & Security Project

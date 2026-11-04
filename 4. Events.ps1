# ============================================================
# Windows Event Forwarding - Subscription Configuration
# Subscription : APP1-SQL
# Collector     : LOKI-APP2
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$EventPath = "C:\Events"
$XmlPath   = Join-Path $EventPath "APP1-SQL.xml"

# ------------------------------------------------------------
# Create directory
# ------------------------------------------------------------

New-Item -Path $EventPath -ItemType Directory -Force |
    Out-Null

# ------------------------------------------------------------
# Subscription XML
# ------------------------------------------------------------

$XmlContent = @'
<?xml version="1.0" encoding="UTF-8"?>
<Subscription xmlns="http://schemas.microsoft.com/2006/03/windows/events/subscription">
    <SubscriptionId>APP1-SQL</SubscriptionId>
    <SubscriptionType>SourceInitiated</SubscriptionType>
    <Description>SQL Server events from APP01</Description>
    <Enabled>true</Enabled>
    <Uri>http://schemas.microsoft.com/wbem/wsman/1/windows/EventLog</Uri>
    <ConfigurationMode>Normal</ConfigurationMode>

    <Delivery Mode="Push">
        <Batching>
            <MaxLatencyTime>30000</MaxLatencyTime>
        </Batching>
        <PushSettings>
            <Heartbeat Interval="60000"/>
        </PushSettings>
    </Delivery>

    <Query>
        <QueryList>
            <Query Id="0">
                <Select Path="Application">
                    *[System[Provider[@Name='MSSQLSERVER'] and (EventID=18456)]]
                </Select>
                <Select Path="System">
                    *[System[(EventID=7034 or EventID=7036)]]
                </Select>
            </Query>
        </QueryList>
    </Query>

    <ReadExistingEvents>false</ReadExistingEvents>
    <TransportName>HTTP</TransportName>
    <ContentFormat>RenderedText</ContentFormat>
    <Locale Language="en-US"/>
    <LogFile>ForwardedEvents</LogFile>
    <PublisherName>Microsoft-Windows-EventCollector</PublisherName>
    <AllowedSourceDomainComputers>O:NSG:BAD:P(A;;GA;;;DC)</AllowedSourceDomainComputers>
</Subscription>
'@

# ------------------------------------------------------------
# Write XML file (UTF-8 without BOM)
# ------------------------------------------------------------

[System.IO.File]::WriteAllText(
    $XmlPath,
    $XmlContent,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "[OK] Subscription XML created." -ForegroundColor Green

# ------------------------------------------------------------
# Register WEC subscription
# ------------------------------------------------------------

wecutil.exe cs $XmlPath

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create WEC subscription."
}

Write-Host "[OK] Subscription APP1-SQL registered." -ForegroundColor Green



# ============================================================
# Windows Event Forwarding - Source Configuration
# Source        : APP1
# Collector     : LOKI-APP2
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Subscription Manager
# ------------------------------------------------------------

$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager"

$CollectorURL = "Server=http://LOKI-APP2.Loki.local:5985/wsman/SubscriptionManager/WEC,Refresh=60"

# Create registry key
New-Item -Path $RegistryPath -Force |
    Out-Null

# Configure collector
New-ItemProperty `
    -Path $RegistryPath `
    -Name "1" `
    -PropertyType String `
    -Value $CollectorURL `
    -Force |
    Out-Null

Write-Host "[OK] SubscriptionManager configured." -ForegroundColor Green

# ------------------------------------------------------------
# Event Log Readers permissions
# ------------------------------------------------------------

Add-LocalGroupMember `
    -Group "Event Log Readers" `
    -Member "NT AUTHORITY\NETWORK SERVICE" `
    -ErrorAction Stop

Write-Host "[OK] NETWORK SERVICE added to Event Log Readers." -ForegroundColor Green

# ------------------------------------------------------------
# Complete
# ------------------------------------------------------------

Write-Host "Windows Event Forwarding source configuration completed." -ForegroundColor Green
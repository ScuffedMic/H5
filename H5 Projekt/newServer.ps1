
# ============================================
# Windows Server - Basic Configuration
# ============================================

# Configuration
$Hostname       = "LOKI-DCTEST1"
$IPAddress      = "192.168.99.37"
$PrefixLength   = 24
$Gateway        = "192.168.99.1"
$DNSServers     = @("192.168.99.30", "192.168.99.31")
$InterfaceAlias = "Ethernet"

# ============================================
# Check administrator privileges
# ============================================

$currentUser = [Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()

if (-not $currentUser.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Error "Run PowerShell as Administrator!"
    exit
}

Write-Host "Starting server configuration..." -ForegroundColor Green

# ============================================
# 1. Configure hostname
# ============================================

Write-Host "Configuring hostname..."

if ($env:COMPUTERNAME -ne $Hostname) {
    Rename-Computer -NewName $Hostname -Force
    Write-Host "Hostname changed to $Hostname"
}
else {
    Write-Host "Hostname already configured."
}

# ============================================
# 2. Configure static IP
# ============================================

Write-Host "Configuring network..."

$Adapter = Get-NetAdapter -Name $InterfaceAlias -ErrorAction Stop

# Disable DHCP
Set-NetIPInterface `
    -InterfaceAlias $InterfaceAlias `
    -AddressFamily IPv4 `
    -Dhcp Disabled

# Remove existing IPv4 addresses
Get-NetIPAddress -InterfaceAlias $InterfaceAlias `
    -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -notlike "169.254.*"
    } |
    Remove-NetIPAddress -Confirm:$false

# Remove existing default routes
Get-NetRoute -InterfaceAlias $InterfaceAlias `
    -AddressFamily IPv4 `
    -DestinationPrefix "0.0.0.0/0" `
    -ErrorAction SilentlyContinue |
    Remove-NetRoute -Confirm:$false

# Configure new IP
New-NetIPAddress `
    -InterfaceAlias $InterfaceAlias `
    -IPAddress $IPAddress `
    -PrefixLength $PrefixLength `
    -DefaultGateway $Gateway

# Configure DNS
Set-DnsClientServerAddress `
    -InterfaceAlias $InterfaceAlias `
    -ServerAddresses $DNSServers

Write-Host "IP configuration completed."

# ============================================
# 3. Enable Remote Desktop
# ============================================

Write-Host "Enabling Remote Desktop..."

# Enable RDP
Set-ItemProperty `
    -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" `
    -Value 0

# Enable Network Level Authentication
Set-ItemProperty `
    -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
    -Name "UserAuthentication" `
    -Value 1

# Enable RDP firewall rules
Enable-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP"
Enable-NetFirewallRule -Name "RemoteDesktop-UserMode-In-UDP"

Write-Host "Remote Desktop enabled."

# ============================================
# 4. Completion
# ============================================

Write-Host ""
Write-Host "===================================="
Write-Host " Basic configuration completed!"
Write-Host "===================================="

Write-Host "Hostname: $Hostname"
Write-Host "IP:       $IPAddress"
Write-Host "Gateway:  $Gateway"
Write-Host "DNS:      $($DNSServers -join ', ')"

Write-Host ""
Write-Host "A restart may be required for hostname changes."
Write-Host "Remember to verify network connectivity."

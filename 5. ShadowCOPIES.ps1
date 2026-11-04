# Run as Administrator

$Drive = "D:"
$TaskName = "D Drive Shadow Copies"

# Configure Shadow Copy storage (15%)
vssadmin add shadowstorage /for=$Drive /on=$Drive /maxsize=15%

# Create initial snapshot
vssadmin create shadow /for=$Drive

# Schedule snapshots every 10 minutes
$Action = New-ScheduledTaskAction `
    -Execute "C:\Windows\System32\vssadmin.exe" `
    -Argument "create shadow /for=$Drive"

$Trigger = New-ScheduledTaskTrigger -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 10)

$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Description "Creates D drive shadow copies every 10 minutes" `
    -Force

Write-Host "Shadow Copies configured successfully!" -ForegroundColor Green

# Display configuration
vssadmin list shadowstorage
Get-ScheduledTask -TaskName $TaskName
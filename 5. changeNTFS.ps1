$Path = "\\Loki-fil1\loki-share\HR"

$OldGroup = "LOKI\SG_IT_RW"
$NewGroup = "LOKI\SG_HR_RW"

# Resolve group identities
$OldSID = (New-Object System.Security.Principal.NTAccount($OldGroup)).
    Translate([System.Security.Principal.SecurityIdentifier])

$NewSID = (New-Object System.Security.Principal.NTAccount($NewGroup)).
    Translate([System.Security.Principal.SecurityIdentifier])

# Get ACL
$Acl = Get-Acl -Path $Path

# Find old group permissions using SID
$OldRules = @($Acl.Access | Where-Object {
    try {
        $_.IdentityReference.Translate(
            [System.Security.Principal.SecurityIdentifier]
        ).Value -eq $OldSID.Value
    }
    catch {
        $false
    }
})

if ($OldRules.Count -eq 0) {
    Write-Host "No permissions found for $OldGroup" -ForegroundColor Yellow
    return
}

foreach ($Rule in $OldRules) {

    Write-Host "Replacing permission: $($Rule.FileSystemRights)"

    # Remove old permission
    [void]$Acl.RemoveAccessRuleSpecific($Rule)

    # Create equivalent permission for new group
    $NewRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $NewSID,
        $Rule.FileSystemRights,
        $Rule.InheritanceFlags,
        $Rule.PropagationFlags,
        $Rule.AccessControlType
    )

    # Add new permission
    [void]$Acl.AddAccessRule($NewRule)
}

# Apply ACL
Set-Acl -Path $Path -AclObject $Acl

Write-Host "Permissions successfully replaced!" -ForegroundColor Green
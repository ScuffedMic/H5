$Path = "D:\Shares\Data"
$OldGroup = "DOMAIN\OldGroup"
$NewGroup = "DOMAIN\NewGroup"

# Hent ACL
$Acl = Get-Acl -Path $Path

# Find eksisterende rettigheder for den gamle gruppe
$OldRules = $Acl.Access | Where-Object {
    $_.IdentityReference -eq $OldGroup
}

foreach ($Rule in $OldRules) {

    # Fjern gammel regel
    $Acl.RemoveAccessRuleSpecific($Rule)

    # Opret tilsvarende regel til den nye gruppe
    $NewRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $NewGroup,
        $Rule.FileSystemRights,
        $Rule.InheritanceFlags,
        $Rule.PropagationFlags,
        $Rule.AccessControlType
    )

    # Tilføj ny regel
    $Acl.AddAccessRule($NewRule)
}

# Anvend ændringerne
Set-Acl -Path $Path -AclObject $Acl

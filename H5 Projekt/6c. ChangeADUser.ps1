# Brugerens login-navn
$Username = "bobbi"

# Nye oplysninger
$GivenName = "Bobbi"
$Surname = "Builder"
$DisplayName = "$GivenName $Surname"
$CommonName = "$GivenName $Surname"

# Hent AD-brugeren
$User = Get-ADUser -Identity $Username

# Opdater AD-attributter
Set-ADUser -Identity $Username `
    -GivenName $GivenName `
    -Surname $Surname `
    -DisplayName $DisplayName

# Opdater Common Name (CN)
Rename-ADObject -Identity $User.DistinguishedName `
    -NewName $CommonName

Write-Host "Brugeren er blevet opdateret: $DisplayName" -ForegroundColor Green


# Opdater DisplayName og Name i Exchange (hvis relevant)

Set-Mailbox -Identity "bobbi" `
    -DisplayName "Bobbi Builder" `
    -Name "Bobbi Builder"
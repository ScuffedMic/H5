$ScopeId
$LeaseDuration

Set-DhcpServer4Scope -ScopeId $ScopeId -LeaseDuration $LeaseDuration

$Startrange
$EndRange

Set-DhcpServer4Scope -ScopeId $ScopeId -StartRange $Startrange -EndRange $EndRange
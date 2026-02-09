

$feature = Get-WindowsFeature DHCP
if (-not $feature.Installed) {
    Install-WindowsFeature DHCP -IncludeManagementTools
}

Add-DhcpServerSecurityGroup | Out-Null
Restart-Service DHCPServer

$scopeName = Read-Host "Nombre del scope"
$startIP  = Read-Host "IP inicial"
$endIP    = Read-Host "IP final"
$gateway  = Read-Host "Gateway"
$lease    = [int](Read-Host "Lease (dias)")

$scopeId = "192.168.100.0"

if (-not (Get-DhcpServerv4Scope -ErrorAction SilentlyContinue | Where-Object {$_.ScopeId -eq $scopeId})) {
    Add-DhcpServerv4Scope `
      -Name $scopeName `
      -StartRange $startIP `
      -EndRange $endIP `
      -SubnetMask 255.255.255.0 `
      -LeaseDuration ([TimeSpan]::FromDays($lease))
}

Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 3 -Value $gateway

Set-DhcpServerv4Scope -ScopeId $scopeId -State Active

Get-Service DHCPServer
Get-DhcpServerv4Lease -ScopeId $scopeId

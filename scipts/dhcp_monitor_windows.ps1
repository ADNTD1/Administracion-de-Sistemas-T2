Write-Host "Estado del servicio DHCP:"
Get-Service DHCPServer

Write-Host ""
Write-Host "Concesiones activas:"
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 | `
Select-Object IPAddress, ClientId, HostName, LeaseExpiryTime

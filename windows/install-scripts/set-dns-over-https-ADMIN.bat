@echo off
powershell.exe -ExecutionPolicy Bypass -Command "$Adapters = @(Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}); Foreach ($Adapter in $Adapters) { Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses ('8.8.8.8','8.8.4.4'); Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses ('2001:4860:4860::8888','2001:4860:4860::8844') }"
echo now go to settings/network and set dns-over-https to automatic template
pause

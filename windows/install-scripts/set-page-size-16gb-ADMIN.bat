@findstr/v "^@f.*&" "%~f0"|powershell -&goto:eof
Get-CimInstance Win32_ComputerSystem | Set-CimInstance -Property @{AutomaticManagedPagefile = $false}
Get-CimInstance -ClassName Win32_PageFileSetting | Where-Object { $_.Name -eq "$env:SystemDrive\pagefile.sys" } | Set-CimInstance -Property @{ InitialSize = 16384; MaximumSize = 16384 }
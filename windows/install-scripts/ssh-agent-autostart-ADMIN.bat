@findstr/v "^@f.*&" "%~f0"|powershell -&goto:eof
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
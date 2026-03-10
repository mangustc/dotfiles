@findstr/v "^@f.*&" "%~f0"|powershell -&goto:eof
$pathToAdd = "$env:USERPROFILE\win\bin"
$oldpath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$oldpath;$pathToAdd", "User")

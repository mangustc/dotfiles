@findstr/v "^@f.*&" "%~f0"|powershell -&goto:eof
& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))

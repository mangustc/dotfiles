@echo off
cls

echo Select an option:
choice /c:12345Q /m "1. 1920x1080@70, 2. 1600x900@76, 3. 1280x720@76, 4. 960x540@76, 5. 1920x1080@60, Q. Quit"

if %ERRORLEVEL%==1 goto Option1
if %ERRORLEVEL%==2 goto Option2
if %ERRORLEVEL%==3 goto Option3
if %ERRORLEVEL%==4 goto Option4
if %ERRORLEVEL%==5 goto Option5
if %ERRORLEVEL%==5 goto End

:Option1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-ScreenResolution.ps1" -Width 1920 -Height 1080 -Frequency 70
goto End

:Option2
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-ScreenResolution.ps1" -Width 1600 -Height 900 -Frequency 76
goto End

:Option3
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-ScreenResolution.ps1" -Width 1280 -Height 720 -Frequency 76
goto End

:Option4
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-ScreenResolution.ps1" -Width 960 -Height 540 -Frequency 76
goto End

:Option5
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-ScreenResolution.ps1" -Width 1920 -Height 1080 -Frequency 60
goto End

:End
echo Exiting...

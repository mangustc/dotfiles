@echo off
cls

echo Select an option:
choice /c:123Q /m "1. 1920x1080@60, 2. 1920x1080@70, 3. 1920x1080@76, Q. Quit"

if %ERRORLEVEL%==1 goto Option1
if %ERRORLEVEL%==2 goto Option2
if %ERRORLEVEL%==3 goto Option3
if %ERRORLEVEL%==4 goto End

:Option1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-ScreenResolution.ps1" -Width 1920 -Height 1080 -Frequency 60
goto End

:Option2
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-ScreenResolution.ps1" -Width 1920 -Height 1080 -Frequency 70
goto End

:Option3
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-ScreenResolution.ps1" -Width 1920 -Height 1080 -Frequency 76
goto End

:End
echo Exiting...

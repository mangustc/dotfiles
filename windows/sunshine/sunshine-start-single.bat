MultiMonitorTool.exe /enable MTT1337
MultiMonitorTool.exe /disable ACR0335
MultiMonitorTool.exe /SetMonitors "Name=MTT1337 Primary=1 Width=%SUNSHINE_CLIENT_WIDTH% Height=%SUNSHINE_CLIENT_HEIGHT% DisplayFrequency=%SUNSHINE_CLIENT_FPS%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-MouseSpeed.ps1" -speed 10

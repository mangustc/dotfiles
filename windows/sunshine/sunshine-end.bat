MultiMonitorTool.exe /disable MTT1337
MultiMonitorTool.exe /enable ACR0335
MultiMonitorTool.exe /SetMonitors "Name=ACR0335 Primary=1 DisplayFrequency=76 PositionX=0 PositionY=0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\Set-MouseSpeed.ps1" -speed 4

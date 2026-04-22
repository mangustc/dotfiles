@findstr/v "^@f.*&" "%~f0"|powershell -&goto:eof

Start-Process "https://github.com/LizardByte/Sunshine/releases"
Start-Process "https://github.com/VirtualDrivers/Virtual-Display-Driver/releases"
echo "unarchive and place it in win directory, install the driver, place vdd_settings.xml in C:\VirtualDisplayDriver, restart driver"
Start-Process "https://www.nirsoft.net/utils/multi_monitor_tool.html"
echo "put MultiMonitorTool.exe in win/bin directory"

echo -e "\nplace apps.json and sunshine.conf in C:\Program Files\Sunshine\config (you may have to change path to scripts, and/or the display id in sunshine configuration)"
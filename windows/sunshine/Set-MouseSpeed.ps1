param([Int32]$Speed=10)

$MethodDefinition = @" 
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")] 
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni); 
"@ 

$User32 = Add-Type -MemberDefinition $MethodDefinition -Name "User32Set" -Namespace Win32Functions -PassThru
$User32::SystemParametersInfo(0x0071,0,$Speed,0) | Out-Null
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSensitivity -Value $Speed
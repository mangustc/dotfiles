[CmdletBinding()]
param(
    [ValidateRange(-1, 256)]
    [int]$PageFileGB = -1,
    [switch]$SkipDns,
    [switch]$SkipPageFile,
    [switch]$SkipZenPolicies,
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"

function Set-CurrentUserExecutionPolicyRegistry {
    $psPolicyPath = "HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
    if (-not (Test-Path -LiteralPath $psPolicyPath)) {
        New-Item -Path $psPolicyPath -Force | Out-Null
    }
    New-ItemProperty -Path $psPolicyPath -Name "ExecutionPolicy" -Value "RemoteSigned" -PropertyType String -Force | Out-Null
}

function Repair-RegistryPathQuotes {
    $targets = @(
        @{ Hive = [Microsoft.Win32.Registry]::LocalMachine; SubKey = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; Label = "Machine" },
        @{ Hive = [Microsoft.Win32.Registry]::CurrentUser; SubKey = "Environment"; Label = "User" }
    )
    foreach ($t in $targets) {
        $key = $null
        try {
            $key = $t.Hive.OpenSubKey($t.SubKey, $true)
            if ($null -eq $key) { continue }
            $raw = $key.GetValue("Path", $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            if ($null -eq $raw) { continue }
            $cleaned = @(
                ([string]$raw) -split ";" |
                    ForEach-Object { $_.Replace('"', '').Trim() } |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            ) -join ";"
            if ($cleaned -cne [string]$raw) {
                $key.SetValue("Path", $cleaned, [Microsoft.Win32.RegistryValueKind]::ExpandString)
                Write-Host "Sanitized $($t.Label) PATH quotes."
            }
        } finally {
            if ($null -ne $key) { $key.Dispose() }
        }
    }
}

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        Set-CurrentUserExecutionPolicyRegistry
    } catch {}

    $argList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`""
    )
    if ($PSBoundParameters.ContainsKey("PageFileGB")) {
        $argList += @("-PageFileGB", "$PageFileGB")
    }
    if ($SkipDns) { $argList += "-SkipDns" }
    if ($SkipPageFile) { $argList += "-SkipPageFile" }
    if ($SkipZenPolicies) { $argList += "-SkipZenPolicies" }
    if ($NoPause) { $argList += "-NoPause" }

    $proc = Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argList -Wait -PassThru
    exit $proc.ExitCode
}

$exitCode = 0
try {
    Write-Host "=== Windows Admin Bootstrap ===" -ForegroundColor Cyan

    Write-Host "[1/7] Setting ExecutionPolicy and sanitizing PATH quotes..."
    Set-CurrentUserExecutionPolicyRegistry
    Repair-RegistryPathQuotes

    Write-Host "[2/7] Enabling Windows Developer Mode (non-admin symlinks)..."
    $appModelPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not (Test-Path -LiteralPath $appModelPath)) {
        New-Item -Path $appModelPath -Force | Out-Null
    }
    New-ItemProperty -Path $appModelPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -PropertyType DWord -Force | Out-Null

    Write-Host "[3/7] Configuring and starting Windows OpenSSH ssh-agent..."
    $sshAgent = Get-Service -Name "ssh-agent" -ErrorAction SilentlyContinue
    if ($null -eq $sshAgent) {
        Write-Host "Installing OpenSSH.Client Windows capability..."
        Add-WindowsCapability -Online -Name "OpenSSH.Client~~~~0.0.1.0" | Out-Null
        $sshAgent = Get-Service -Name "ssh-agent"
    }
    Set-Service -Name "ssh-agent" -StartupType Automatic
    if ($sshAgent.Status -ne "Running") {
        Start-Service -Name "ssh-agent"
    }

    Write-Host "[4/7] Setting hardware clock to UTC (RealTimeIsUniversal=1)..."
    $tzPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
    New-ItemProperty -Path $tzPath -Name "RealTimeIsUniversal" -Value 1 -PropertyType DWord -Force | Out-Null

    Write-Host "[5/7] Unlocking CPU performance boost mode option..."
    $cpuBoostPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
    if (Test-Path -LiteralPath $cpuBoostPath) {
        New-ItemProperty -Path $cpuBoostPath -Name "Attributes" -Value 2 -PropertyType DWord -Force | Out-Null
    } else {
        Write-Warning "CPU boost power setting registry key not found; skipping."
    }

    if (-not $SkipDns) {
        Write-Host "[6/7] Configuring Quad9 DNS + automatic DoH on active adapters..."
        $ipv4Servers = @("9.9.9.9", "149.112.112.112")
        $ipv6Servers = @("2620:fe::fe", "2620:fe::9")
        $allDnsServers = $ipv4Servers + $ipv6Servers
        $quad9DohTemplate = "https://dns.quad9.net/dns-query"

        if (Get-Command "Add-DnsClientDohServerAddress" -ErrorAction SilentlyContinue) {
            foreach ($server in $allDnsServers) {
                try {
                    $existingDoh = Get-DnsClientDohServerAddress -ServerAddress $server -ErrorAction SilentlyContinue
                    if ($null -eq $existingDoh) {
                        Add-DnsClientDohServerAddress -ServerAddress $server -DohTemplate $quad9DohTemplate -AllowFallbackToUdp $true -AutoUpgrade $true | Out-Null
                    } else {
                        Set-DnsClientDohServerAddress -ServerAddress $server -DohTemplate $quad9DohTemplate -AllowFallbackToUdp $true -AutoUpgrade $true | Out-Null
                    }
                } catch {
                    Write-Warning "Could not register Quad9 DoH template for ${server}: $($_.Exception.Message)"
                }
            }
        }

        $adapters = @(
            Get-NetAdapter | Where-Object {
                $_.Status -eq "Up" -and
                $_.InterfaceDescription -notmatch "Wintun|Mihomo|Clash|WireGuard|Tailscale|Hyper-V|Loopback"
            }
        )
        foreach ($adapter in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $ipv4Servers
            } catch {
                Write-Warning "Could not set IPv4 DNS on $($adapter.Name): $($_.Exception.Message)"
            }
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $ipv6Servers
            } catch {
                Write-Warning "Could not set IPv6 DNS on $($adapter.Name): $($_.Exception.Message)"
            }
            try {
                foreach ($server in $allDnsServers) {
                    $dohPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$($adapter.InterfaceGuid)\DohInterfaceSettings\Doh\$server"
                    if (-not (Test-Path -LiteralPath $dohPath)) {
                        New-Item -Path $dohPath -Force | Out-Null
                    }
                    New-ItemProperty -Path $dohPath -Name "DohFlags" -Value ([uint64]1) -PropertyType QWord -Force | Out-Null
                }
            } catch {
                Write-Warning "Could not configure DoH registry flags for $($adapter.Name): $($_.Exception.Message)"
            }
        }
        Write-Host "Note: Verify DNS-over-HTTPS is set to Automatic in Settings > Network if needed." -ForegroundColor Yellow
    } else {
        Write-Host "[6/7] Skipping DNS configuration (-SkipDns)."
    }

    if (-not $SkipPageFile) {
        if ($PageFileGB -eq -1) {
            $choice = Read-Host "Pagefile size: [1] 16 GB, [2] 10 GB, [S] Skip (default: S)"
            switch ($choice.Trim().ToUpperInvariant()) {
                "1" { $PageFileGB = 16 }
                "2" { $PageFileGB = 10 }
                default { $PageFileGB = 0 }
            }
        }

        if ($PageFileGB -gt 0) {
            Write-Host "Configuring fixed pagefile size: $PageFileGB GB..."
            $sizeMB = $PageFileGB * 1024
            $cs = Get-CimInstance -ClassName Win32_ComputerSystem
            if ($cs.AutomaticManagedPagefile) {
                Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $false }
            }
            $pageFileName = "$env:SystemDrive\pagefile.sys"
            $pf = Get-CimInstance -ClassName Win32_PageFileSetting | Where-Object { $_.Name -ieq $pageFileName }
            if ($null -eq $pf) {
                $pf = New-CimInstance -ClassName Win32_PageFileSetting -Property @{ Name = $pageFileName }
            }
            Set-CimInstance -InputObject $pf -Property @{ InitialSize = $sizeMB; MaximumSize = $sizeMB }
        } else {
            Write-Host "Skipping pagefile configuration."
        }
    } else {
        Write-Host "Skipping pagefile configuration (-SkipPageFile)."
    }

    if (-not $SkipZenPolicies) {
        Write-Host "[7/7] Copying Zen Browser policies.json..."
        $zenSource = Join-Path $PSScriptRoot "configs\zen-browser\policies.json"
        $zenDistDir = "C:\Program Files\Zen Browser\distribution"
        $zenDest = Join-Path $zenDistDir "policies.json"

        if (Test-Path -LiteralPath $zenDistDir) {
            $dirItem = Get-Item -LiteralPath $zenDistDir -Force
            if (($dirItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                [System.IO.Directory]::Delete($zenDistDir, $false)
            }
        }
        if (-not (Test-Path -LiteralPath $zenDistDir)) {
            New-Item -Path $zenDistDir -ItemType Directory -Force | Out-Null
        }
        if (Test-Path -LiteralPath $zenDest) {
            $fileAttrs = [System.IO.File]::GetAttributes($zenDest)
            if (($fileAttrs -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                [System.IO.File]::Delete($zenDest)
            }
        }
        Copy-Item -LiteralPath $zenSource -Destination $zenDest -Force
    } else {
        Write-Host "[7/7] Skipping Zen Browser policies.json (-SkipZenPolicies)."
    }

    Write-Host ""
    Write-Host "Bootstrap complete." -ForegroundColor Green
} catch {
    $exitCode = 1
    Write-Host ""
    Write-Host "Bootstrap failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.InvocationInfo.PositionMessage) {
        Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkYellow
    }
} finally {
    if (-not $NoPause) {
        Read-Host "Press Enter to close" | Out-Null
    }
}

exit $exitCode

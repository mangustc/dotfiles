[CmdletBinding()]
param(
    [ValidateSet("", "packages", "win-bin", "git", "neovim")]
    [string]$Module = "",
    [switch]$SkipPackages,
    [switch]$Upgrade
)

$ErrorActionPreference = "Stop"

$WindowsDir = $PSScriptRoot
$DotfilesDir = (Resolve-Path (Join-Path $WindowsDir "..")).Path

function Ensure-StandaloneDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            [System.IO.Directory]::Delete($Path, $false)
        }
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function Remove-IfReparsePoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        $attrs = [System.IO.File]::GetAttributes($Path)
        if (($attrs -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            if (($attrs -band [System.IO.FileAttributes]::Directory) -ne 0) {
                [System.IO.Directory]::Delete($Path, $false)
            } else {
                [System.IO.File]::Delete($Path)
            }
        }
    }
}

function Copy-StandaloneFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Source file not found: $Source"
    }

    $parentDir = Split-Path -Path $Destination -Parent
    Ensure-StandaloneDirectory -Path $parentDir
    Remove-IfReparsePoint -Path $Destination
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Write-StandaloneFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $parentDir = Split-Path -Path $Path -Parent
    Ensure-StandaloneDirectory -Path $parentDir
    Remove-IfReparsePoint -Path $Path
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Install-WingetPackages {
    param(
        [string[]]$PackageIds
    )

    if ($SkipPackages -or $null -eq $PackageIds -or $PackageIds.Count -eq 0) {
        return
    }

    if ($null -eq (Get-Command "winget" -ErrorAction SilentlyContinue)) {
        throw "winget was not found in PATH."
    }

    $installedIds = New-Object "System.Collections.Generic.HashSet[string]" ([System.StringComparer]::OrdinalIgnoreCase)
    $tmpJson = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dotfiles-winget-" + [System.Guid]::NewGuid().ToString("N") + ".json")
    try {
        $null = & winget export -o $tmpJson --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $tmpJson)) {
            $exportData = Get-Content -LiteralPath $tmpJson -Raw | ConvertFrom-Json
            if ($null -ne $exportData.Sources) {
                foreach ($source in $exportData.Sources) {
                    if ($null -ne $source.Packages) {
                        foreach ($pkg in $source.Packages) {
                            if (-not [string]::IsNullOrWhiteSpace($pkg.PackageIdentifier)) {
                                [void]$installedIds.Add($pkg.PackageIdentifier.Trim())
                            }
                        }
                    }
                }
            }
        }
    } catch {
        Write-Warning "Could not query installed winget packages via export; attempting requested installs directly."
    } finally {
        if (Test-Path -LiteralPath $tmpJson) {
            Remove-Item -LiteralPath $tmpJson -Force -ErrorAction SilentlyContinue
        }
    }

    $missingIds = @()
    foreach ($id in $PackageIds) {
        if (-not $installedIds.Contains($id)) {
            $missingIds += $id
        }
    }

    foreach ($id in $missingIds) {
        Write-Host "Installing $id..."
        & winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -notin @(0, -1978335189, -1978335135)) {
            throw "winget install failed for '$id' with exit code $LASTEXITCODE"
        }
    }
}

function Add-UserPathEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Entry
    )

    $normalizedTarget = $Entry.Trim().TrimEnd("\")
    $hkcuEnv = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment", $true)
    try {
        $rawUserPath = $null
        if ($null -ne $hkcuEnv) {
            $rawUserPath = $hkcuEnv.GetValue("Path", $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        }
        $parts = @()
        if ($null -ne $rawUserPath) {
            $parts = @(
                ([string]$rawUserPath) -split ";" |
                    ForEach-Object { $_.Replace('"', '').Trim() } |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            )
        }

        $existsInUser = $false
        foreach ($part in $parts) {
            if ($part.TrimEnd("\").Equals($normalizedTarget, [System.StringComparison]::OrdinalIgnoreCase)) {
                $existsInUser = $true
                break
            }
        }

        $newParts = if ($existsInUser) { $parts } else { $parts + @($Entry) }
        $newUserPath = $newParts -join ";"
        if ($null -eq $rawUserPath -or $newUserPath -cne [string]$rawUserPath) {
            if ($null -eq $hkcuEnv) {
                $hkcuEnv = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("Environment")
            }
            $hkcuEnv.SetValue("Path", $newUserPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
            if (-not $existsInUser) {
                Write-Host "Added to User PATH: $Entry"
            }
        }
    } finally {
        if ($null -ne $hkcuEnv) { $hkcuEnv.Dispose() }
    }

    $sessionParts = @(
        $env:Path -split ";" |
            ForEach-Object { $_.Replace('"', '').Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    $existsInSession = $false
    foreach ($part in $sessionParts) {
        if ($part.TrimEnd("\").Equals($normalizedTarget, [System.StringComparison]::OrdinalIgnoreCase)) {
            $existsInSession = $true
            break
        }
    }
    $env:Path = $(if ($existsInSession) { $sessionParts } else { $sessionParts + @($Entry) }) -join ";"
}

if ($Module -in @("", "packages")) {
    Write-Host "[module: packages]" -ForegroundColor Cyan
    $packagesFile = Join-Path $WindowsDir "packages-windows"
    if (-not (Test-Path -LiteralPath $packagesFile)) {
        throw "Packages file not found: $packagesFile"
    }

    $pkgIds = @(
        Get-Content -LiteralPath $packagesFile | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith("#")) {
                $line
            }
        }
    )
    Install-WingetPackages -PackageIds $pkgIds

    if ($Upgrade -and -not $SkipPackages) {
        Write-Host "Upgrading installed winget packages..."
        & winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    }
}

if ($Module -in @("", "win-bin")) {
    Write-Host "[module: win-bin]" -ForegroundColor Cyan
    $winBinDir = Join-Path $env:USERPROFILE "win\bin"
    Ensure-StandaloneDirectory -Path $winBinDir
    Add-UserPathEntry -Entry $winBinDir

    $copiedTools = @(
        (Join-Path $WindowsDir "chres\chres.bat"),
        (Join-Path $WindowsDir "chres\Set-ScreenResolution.bat"),
        (Join-Path $WindowsDir "chres\Set-ScreenResolution.ps1"),
        (Join-Path $WindowsDir "pgen\pgen.bat")
    )
    foreach ($tool in $copiedTools) {
        $dest = Join-Path $winBinDir (Split-Path -Path $tool -Leaf)
        Copy-StandaloneFile -Source $tool -Destination $dest
    }

    $configScriptPath = Join-Path $WindowsDir "configuration-windows.ps1"

    $winupdCmd = @"
@echo off
set "PATH=%PATH:"=%"
if not exist "$configScriptPath" (
    echo Error: dotfiles not found at "$DotfilesDir" >&2
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$configScriptPath" %*
"@
    Write-StandaloneFile -Path (Join-Path $winBinDir "winupd.cmd") -Content $winupdCmd

    $wingitCmd = @"
@echo off
set "PATH=%PATH:"=%"
if exist "C:\Program Files\Git\mingw64\bin\git-askpass.exe" (
    set "SSH_ASKPASS=C:\Program Files\Git\mingw64\bin\git-askpass.exe"
    set "SSH_ASKPASS_REQUIRE=force"
)
if not exist "$DotfilesDir" (
    echo Error: dotfiles not found at "$DotfilesDir" >&2
    exit /b 1
)
lazygit -p "$DotfilesDir" %*
"@
    Write-StandaloneFile -Path (Join-Path $winBinDir "wingit.cmd") -Content $wingitCmd

    $winconfCmd = @"
@echo off
set "PATH=%PATH:"=%"
if not exist "$configScriptPath" (
    echo Error: dotfiles not found at "$DotfilesDir" >&2
    exit /b 1
)
set "DOTFILES_EDITOR=%EDITOR%"
if "%DOTFILES_EDITOR%"=="" set "DOTFILES_EDITOR=nvim"
"%DOTFILES_EDITOR%" "$configScriptPath"
"@
    Write-StandaloneFile -Path (Join-Path $winBinDir "winconf.cmd") -Content $winconfCmd

    $dotgitCmd = @"
@echo off
set "PATH=%PATH:"=%"
if exist "C:\Program Files\Git\mingw64\bin\git-askpass.exe" (
    set "SSH_ASKPASS=C:\Program Files\Git\mingw64\bin\git-askpass.exe"
    set "SSH_ASKPASS_REQUIRE=force"
)
if not exist "$DotfilesDir" (
    echo Error: dotfiles not found at "$DotfilesDir" >&2
    exit /b 1
)
lazygit -p "$DotfilesDir" %*
"@
    Write-StandaloneFile -Path (Join-Path $winBinDir "dotgit.cmd") -Content $dotgitCmd

    $clashConfigDir = Join-Path $DotfilesDir "secrets\clash-config"
    $clashgitCmd = @"
@echo off
set "PATH=%PATH:"=%"
if exist "C:\Program Files\Git\mingw64\bin\git-askpass.exe" (
    set "SSH_ASKPASS=C:\Program Files\Git\mingw64\bin\git-askpass.exe"
    set "SSH_ASKPASS_REQUIRE=force"
)
if not exist "$clashConfigDir\.git" (
    echo Error: clash-config repo not found at "$clashConfigDir" >&2
    exit /b 1
)
lazygit -p "$clashConfigDir" %*
"@
    Write-StandaloneFile -Path (Join-Path $winBinDir "clashgit.cmd") -Content $clashgitCmd

    $clashsyncPs1 = @'
param(
    [string]$Message = "sync"
)

$ErrorActionPreference = "Stop"
$clashDir = "__CLASH_CONFIG_DIR__"

if (-not (Test-Path -LiteralPath (Join-Path $clashDir ".git"))) {
    [Console]::Error.WriteLine("Error: clash-config repo not found at '$clashDir'")
    exit 1
}

Push-Location -LiteralPath $clashDir
try {
    $ErrorActionPreference = "Continue"
    $gitAskPass = "C:\Program Files\Git\mingw64\bin\git-askpass.exe"
    if (Test-Path -LiteralPath $gitAskPass) {
        $env:SSH_ASKPASS = $gitAskPass
        $env:SSH_ASKPASS_REQUIRE = "force"
    }

    $rebaseMerge = (& git rev-parse --git-path rebase-merge 2>$null)
    $rebaseApply = (& git rev-parse --git-path rebase-apply 2>$null)
    if (($rebaseMerge -and (Test-Path -LiteralPath $rebaseMerge)) -or ($rebaseApply -and (Test-Path -LiteralPath $rebaseApply))) {
        [Console]::Error.WriteLine("Error: rebase already in progress in '$clashDir' - resolve with 'clashgit'.")
        exit 1
    }

    $dirty = @(& git status --porcelain)
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    if ($dirty.Count -gt 0) {
        if ([string]::IsNullOrWhiteSpace($Message)) { $Message = "sync" }
        & git add -A
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        & git commit -m $Message
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    & git pull --rebase
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("Error: git pull --rebase failed - run 'clashgit' to inspect/resolve.")
        exit $LASTEXITCODE
    }

    $aheadRaw = (& git rev-list --count "@{u}..HEAD" 2>$null)
    if ($LASTEXITCODE -ne 0 -or ([int]$aheadRaw -gt 0)) {
        & git push
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } else {
        Write-Host "clash-config is already in sync." -ForegroundColor Green
    }
} finally {
    Pop-Location
}
'@.Replace("__CLASH_CONFIG_DIR__", $clashConfigDir)
    Write-StandaloneFile -Path (Join-Path $winBinDir "clashsync.ps1") -Content $clashsyncPs1

    $clashsyncCmd = @'
@echo off
set "PATH=%PATH:"=%"
if exist "C:\Program Files\Git\mingw64\bin\git-askpass.exe" (
    set "SSH_ASKPASS=C:\Program Files\Git\mingw64\bin\git-askpass.exe"
    set "SSH_ASKPASS_REQUIRE=force"
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0clashsync.ps1" %*
'@
    Write-StandaloneFile -Path (Join-Path $winBinDir "clashsync.cmd") -Content $clashsyncCmd
}

if ($Module -in @("", "git")) {
    Write-Host "[module: git]" -ForegroundColor Cyan
    if ($Module -eq "git") {
        Install-WingetPackages -PackageIds @("Git.Git", "GitHub.cli")
    }

    Copy-StandaloneFile -Source (Join-Path $WindowsDir "configs\git\.gitconfig") -Destination (Join-Path $env:USERPROFILE ".gitconfig")
    Copy-StandaloneFile -Source (Join-Path $DotfilesDir "modules\git\config.yml") -Destination (Join-Path $env:APPDATA "GitHub CLI\config.yml")

    $gitAskPass = "C:\Program Files\Git\mingw64\bin\git-askpass.exe"
    if (Test-Path -LiteralPath $gitAskPass) {
        [Environment]::SetEnvironmentVariable("SSH_ASKPASS", $gitAskPass, "User")
        [Environment]::SetEnvironmentVariable("SSH_ASKPASS_REQUIRE", "force", "User")
        $env:SSH_ASKPASS = $gitAskPass
        $env:SSH_ASKPASS_REQUIRE = "force"
    }
}

if ($Module -in @("", "neovim")) {
    Write-Host "[module: neovim]" -ForegroundColor Cyan
    if ($Module -eq "neovim") {
        Install-WingetPackages -PackageIds @(
            "Neovim.Neovim",
            "tree-sitter.tree-sitter-cli",
            "junegunn.fzf",
            "BurntSushi.ripgrep.MSVC",
            "sharkdp.fd",
            "zig.zig"
        )
    }

    Copy-StandaloneFile -Source (Join-Path $DotfilesDir "modules\neovim\init.lua") -Destination (Join-Path $env:LOCALAPPDATA "nvim\init.lua")
    [Environment]::SetEnvironmentVariable("EDITOR", "nvim", "User")
    $env:EDITOR = "nvim"
}

Write-Host "Windows configuration applied successfully." -ForegroundColor Green

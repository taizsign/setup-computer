$ErrorActionPreference = "SilentlyContinue"

# relancement en admin si necessaire
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm raphael-jacquis.fr | iex`"" -Verb RunAs
    exit
}

Clear-Host

Write-Host ""
Write-Host "  +======================================+" -ForegroundColor Cyan
Write-Host "  |                                      |" -ForegroundColor Cyan
Write-Host "  |   " -ForegroundColor Cyan -NoNewline
Write-Host "PC SETUP" -ForegroundColor White -NoNewline
Write-Host "                           |" -ForegroundColor Cyan
Write-Host "  |   " -ForegroundColor Cyan -NoNewline
Write-Host "raphael-jacquis.fr" -ForegroundColor DarkCyan -NoNewline
Write-Host "                 |" -ForegroundColor Cyan
Write-Host "  |                                      |" -ForegroundColor Cyan
Write-Host "  +======================================+" -ForegroundColor Cyan
Write-Host ""

# verification de l'OS

$winVer = [System.Environment]::OSVersion.Version
if ($winVer.Major -lt 10) {
    Write-Host "  [!] Windows 10 minimum requis. Script annule." -ForegroundColor Red
    Read-Host "`n  Appuie sur Entree pour quitter"
    exit 1
}

# Winget

$useWinget = $false

if (Get-Command winget -ErrorAction SilentlyContinue) {
    $useWinget = $true
    Write-Host "  [*] winget detecte." -ForegroundColor DarkGray
} else {
    Write-Host "  [*] winget absent, installation de Chocolatey..." -ForegroundColor Yellow

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # recharger le PATH pour que choco soit disponible dans la session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] Chocolatey installe." -ForegroundColor Green
    } else {
        Write-Host "  [!] Echec installation Chocolatey. Verifie ta connexion." -ForegroundColor Red
        Read-Host "`n  Appuie sur Entree pour quitter"
        exit 1
    }
}

# installation

function Install-App {
    param (
        [string]$Nom,
        [string]$WingetId,
        [string]$ChocoId
    )

    Write-Host "  [>] $Nom..." -ForegroundColor Cyan -NoNewline

    if ($useWinget) {
        winget install --id $WingetId --silent --accept-source-agreements --accept-package-agreements | Out-Null
        $code = $LASTEXITCODE
    } else {
        choco install $ChocoId -y --no-progress | Out-Null
        $code = $LASTEXITCODE
    }

    if ($code -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } elseif ($code -eq -1978335189) {
        Write-Host " deja installe" -ForegroundColor DarkGray
    } else {
        Write-Host " erreur (code $code)" -ForegroundColor Yellow
    }
}

# windows update

Write-Host ""
Write-Host "  [*] Ouverture de Windows Update..." -ForegroundColor Yellow
Start-Process "ms-settings:windowsupdate"
Start-Sleep -Milliseconds 800

# logiciels 

Write-Host ""
Write-Host "  Installation des logiciels..." -ForegroundColor White
Write-Host ""

Install-App "Google Chrome"       "Google.Chrome"                 "googlechrome"
Install-App "Adobe Acrobat Reader" "Adobe.Acrobat.Reader.64-bit"  "adobereader"
Install-App "Apache OpenOffice"   "Apache.OpenOffice"             "openoffice"
Install-App "VLC media player"    "VideoLAN.VLC"                  "vlc"

# runtimes

Write-Host ""
Write-Host "  Installation des runtimes..." -ForegroundColor White
Write-Host ""

Install-App "Visual C++ Redistributables" "Microsoft.VCRedist.2015+.x64"  "vcredist140"
Install-App ".NET Desktop Runtime 8"      "Microsoft.DotNet.DesktopRuntime.8" "dotnet-desktopruntime"

# optimisations systeme

Write-Host ""
Write-Host "  [*] Application des optimisations systeme..." -ForegroundColor Yellow

# mode haute performance
powercfg -setactive SCHEME_MIN | Out-Null
Write-Host "  [OK] Plan d'alimentation : Haute performance" -ForegroundColor Green

# désactivation Xbox gamebar
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
Write-Host "  [OK] Xbox Game Bar desactive" -ForegroundColor Green

# désactivation de la telemetrie de base
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
Write-Host "  [OK] Telemetrie reduite" -ForegroundColor Green

# driver GPU

Write-Host ""
Write-Host "  ---------------------------------" -ForegroundColor DarkGray
Write-Host "   Installation du driver GPU" -ForegroundColor White
Write-Host "  ---------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "    1  ->  NVIDIA App" -ForegroundColor White
Write-Host "    2  ->  AMD Software Adrenalin" -ForegroundColor White
Write-Host "    0  ->  Ignorer" -ForegroundColor DarkGray
Write-Host ""

do {
    $choix = Read-Host "  Tapez votre choix"
} while ($choix -notin @("0", "1", "2"))

Write-Host ""

switch ($choix) {
    "1" { Install-App "NVIDIA App"          "Nvidia.NvidiaApp"   "nvidia-display-driver" }
    "2" { Install-App "AMD Software"        "AMD.AMDSoftware"    "amd-ryzen-master" }
    "0" { Write-Host "  [*] Driver GPU ignore." -ForegroundColor DarkGray }
}

# fin

Write-Host ""
Write-Host "  =================================" -ForegroundColor Cyan
Write-Host "      Installation terminee !      " -ForegroundColor Green
Write-Host "   Redemarrage recommande.         " -ForegroundColor Yellow
Write-Host "  =================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "  Appuie sur Entree pour fermer"

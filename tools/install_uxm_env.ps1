<#
install_uxm_env.ps1
Basit Windows kurucu: FreeBASIC x64 tercih eder, NASM ve Node.js'i winget ile kurmaya çalışır.
Varsayılan olarak tools\ içine FreeBASIC'i indirip çıkarır (kullanıcı onayı ister).
Kullanım: powershell -ExecutionPolicy Bypass -File tools\install_uxm_env.ps1 [-Force]
#>

param(
    [switch]$Force
)

function Ensure-Admin {
    $current = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Bu script bazı adımlar için Yönetici hakları gerektirebilir. Lütfen PowerShell'i Yönetici olarak çalıştırın veya -Force ile devam edin." -ForegroundColor Yellow
    }
}

function Try-WingetInstall([string]$id, [string]$name) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "winget ile $name yükleniyor..."
        winget install --silent --accept-package-agreements --accept-source-agreements --id $id || return $false
        return $true
    }
    return $false
}

function Download-And-Extract($url, $outDir) {
    $tmp = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName() + ".zip")
    Write-Host "İndiriliyor: $url -> $tmp"
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
    Write-Host "Zip çıkarılıyor -> $outDir"
    Expand-Archive -Path $tmp -DestinationPath $outDir -Force
    Remove-Item $tmp -Force
}

Ensure-Admin

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root

Write-Host "UXM ortam kurucusu: FreeBASIC x64 (önerilen), NASM, Node.js, VSCode (isteğe bağlı)" -ForegroundColor Cyan

# 1) NASM
if (-not (Get-Command nasm -ErrorAction SilentlyContinue)) {
    Write-Host "NASM bulunamadı. winget ile yüklemeyi deneyecek..."
    if (-not (Try-WingetInstall 'Nasm.Nasm' 'NASM')) {
        Write-Host "winget yok veya NASM bulunamadı. Lütfen NASM'i manuel kurun ve PATH'e ekleyin." -ForegroundColor Yellow
    }
} else { Write-Host "NASM zaten yüklü: $(Get-Command nasm)." }

# 2) Node.js (npm)
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js / npm bulunamadı. winget ile yüklemeyi deneyecek..."
    if (-not (Try-WingetInstall 'OpenJS.NodeJS.LTS' 'Node.js LTS')) {
        Write-Host "winget yok veya NodeJS bulunamadı. Lütfen Node.js'i manuel kurun." -ForegroundColor Yellow
    }
} else { Write-Host "npm zaten mevcut." }

# 3) FreeBASIC x64
$fbDest = Join-Path $root 'tools\FreeBASIC-1.10.1-win64'
if (-not (Test-Path (Join-Path $fbDest 'fbc.exe')) -or $Force) {
    Write-Host "FreeBASIC x64 bulunamadı (tools\FreeBASIC-1.10.1-win64). İndirilsin mi? (Y/N)"
    $resp = 'Y'
    if (-not $Force) { $resp = Read-Host }
    if ($resp -match '^[Yy]') {
        $fbUrl = 'https://prdownloads.sourceforge.net/fbc/fbc-1.10.1-win64.zip'
        try {
            Download-And-Extract $fbUrl $fbDest
            Write-Host "FreeBASIC indirildi ve çıkarıldı: $fbDest"
            & setx FBC64 "$($fbDest)\fbc.exe" | Out-Null
        } catch {
            Write-Host "FreeBASIC indirilemedi: $_" -ForegroundColor Red
            Write-Host "Lütfen manuel indirip tools\FreeBASIC-1.10.1-win64 içine çıkartın." -ForegroundColor Yellow
        }
    } else {
        Write-Host "FreeBASIC kurulumu atlandı. build_one_native.bat, sistem PATH'indeki fbc'yi kullanacak." -ForegroundColor Yellow
    }
} else { Write-Host "FreeBASIC x64 zaten mevcut: $fbDest" }

Write-Host "Kurulum tamamlandı (varsa). Lütfen yeni PATH/FBC64 ayarları için terminali yeniden başlatın veya oturumu kapatıp açın." -ForegroundColor Green

Write-Host "Not: Bu script bazı adımlar için winget, yönetici hakları veya internet bağlantısı gerektirebilir. Manuel kurulum gerekirse README'ye bakın." -ForegroundColor Cyan

param(
    [string]$OutDir = "dist",
    [string]$PackageName = "UXM_v33_standalone",
    [switch]$SkipBuild,
    [switch]$SkipToolchainCopy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$OutRoot = Join-Path $Root $OutDir
$Stage = Join-Path $OutRoot $PackageName
$ZipPath = Join-Path $OutRoot ($PackageName + ".zip")

function Write-Step([string]$Message) {
    Write-Host "[package] $Message"
}

function Copy-IfExists([string]$SourcePath, [string]$TargetPath) {
    if (Test-Path $SourcePath) {
        $targetParent = Split-Path -Parent $TargetPath
        if (-not (Test-Path $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
        Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Force
        return $true
    }
    return $false
}

Write-Step "root=$Root"

if (-not $SkipBuild) {
    Write-Step "build_native.bat calistiriliyor"
    Push-Location $Root
    try {
        & (Join-Path $Root "build_native.bat")
        if ($LASTEXITCODE -ne 0) {
            throw "build_native.bat basarisiz (exit=$LASTEXITCODE)"
        }
    }
    finally {
        Pop-Location
    }
}

if (Test-Path $Stage) {
    Write-Step "eski stage temizleniyor: $Stage"
    Remove-Item -Path $Stage -Recurse -Force
}
if (-not (Test-Path $OutRoot)) {
    New-Item -ItemType Directory -Path $OutRoot -Force | Out-Null
}
New-Item -ItemType Directory -Path $Stage -Force | Out-Null

Write-Step "temel dosyalar kopyalaniyor"
$files = @(
    "build_native.bat",
    "build_one_native.bat",
    "run_all_expected_tests_no_build.bat",
    "rtxz.bat",
    "run_tests_native.bat",
    "pck.md",
    "readme.md",
    "README_V19.md"
)
foreach ($f in $files) {
    $src = Join-Path $Root $f
    $dst = Join-Path $Stage $f
    [void](Copy-IfExists $src $dst)
}

Write-Step "temel klasorler kopyalaniyor"
$dirs = @(
    "uxm",
    "config",
    "docs",
    "tools\\vscode_integration"
)
foreach ($d in $dirs) {
    $src = Join-Path $Root $d
    $dst = Join-Path $Stage $d
    [void](Copy-IfExists $src $dst)
}

Write-Step "runner scriptleri kopyalaniyor"
$toolFiles = @(
    "tools\\UXM_ALL_EXPECT_RUNNER.py",
    "tools\\UXM_EXPECT_RUNNER_V2.py"
)
foreach ($tf in $toolFiles) {
    $src = Join-Path $Root $tf
    $dst = Join-Path $Stage $tf
    [void](Copy-IfExists $src $dst)
}

Write-Step "build artefaktlari kopyalaniyor"
$buildExe = Join-Path $Root "build\\exe"
if (Test-Path $buildExe) {
    [void](Copy-IfExists $buildExe (Join-Path $Stage "build\\exe"))
}

if (-not $SkipToolchainCopy) {
    Write-Step "toolchain aranip kopyalaniyor"

    $fbcCandidates = @(
        (Join-Path $Root "tools\\FreeBASIC-1.10.1-win64"),
        "C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64",
        "C:\Program Files\FreeBASIC"
    )

    $fbcCopied = $false
    foreach ($cand in $fbcCandidates) {
        if (Test-Path (Join-Path $cand "fbc.exe")) {
            Write-Step "FreeBASIC bulundu: $cand"
            [void](Copy-IfExists $cand (Join-Path $Stage "tools\\FreeBASIC-1.10.1-win64"))
            $fbcCopied = $true
            break
        }
    }
    if (-not $fbcCopied) {
        Write-Step "UYARI: FreeBASIC bulunamadi, dis ortam gerekecek"
    }

    $nasmCmd = Get-Command nasm -ErrorAction SilentlyContinue
    if ($nasmCmd -and (Test-Path $nasmCmd.Source)) {
        $nasmTargetDir = Join-Path $Stage "tools\\nasm"
        New-Item -ItemType Directory -Path $nasmTargetDir -Force | Out-Null
        Copy-Item -Path $nasmCmd.Source -Destination (Join-Path $nasmTargetDir "nasm.exe") -Force
        Write-Step "NASM kopyalandi: $($nasmCmd.Source)"
    }
    else {
        Write-Step "UYARI: NASM PATH'te bulunamadi"
    }
}

Write-Step "standalone env batch olusturuluyor"
$envBat = @"
@echo off
setlocal
set "ROOT=%~dp0"
if exist "%ROOT%tools\FreeBASIC-1.10.1-win64\fbc.exe" set "FBC64=%ROOT%tools\FreeBASIC-1.10.1-win64\fbc.exe"
if exist "%ROOT%tools\nasm\nasm.exe" set "PATH=%ROOT%tools\nasm;%PATH%"
echo Standalone UXM env hazirlandi.
echo FBC64=%FBC64%
endlocal
"@
Set-Content -Path (Join-Path $Stage "set_env_standalone.bat") -Value $envBat -Encoding ASCII

Write-Step "standalone README olusturuluyor"
$readme = @"
# UXM V33 Standalone Paket

## 1) Ortami hazirla

    set_env_standalone.bat

## 2) Derleyiciyi derle

    build_native.bat

## 3) Tek test derle/calistir

    build_one_native.bat uxm\tests\fp\test_fp01_add_int.uxm

## 4) Toplu test

    rtxz.bat

## 5) Expected test (no-build)

    run_all_expected_tests_no_build.bat --limit 100

Not:
- pck.md dosyasi programlama rehberidir.
- docs\uxm_compiler_mimarisi.md mimari grafiktir.
"@
Set-Content -Path (Join-Path $Stage "README_STANDALONE.md") -Value $readme -Encoding ASCII

if (Test-Path $ZipPath) {
    Write-Step "eski zip siliniyor: $ZipPath"
    Remove-Item -Path $ZipPath -Force
}

Write-Step "zip olusturuluyor"
Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $ZipPath -CompressionLevel Optimal -Force

Write-Step "tamamlandi"
Write-Host "STAGE=$Stage"
Write-Host "ZIP=$ZipPath"

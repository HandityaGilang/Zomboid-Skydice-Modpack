@echo off
setlocal
cd /d "%~dp0"

echo ========================================
echo   SKYDICE MODPACK MANIFEST BUILDER
echo ========================================
echo.

if not exist "Build_Manifest.ps1" (
    echo [ERROR] Build_Manifest.ps1 tidak ditemukan.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build_Manifest.ps1"

echo.
pause

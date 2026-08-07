@echo off
setlocal
cd /d "%~dp0"
title Skydice Manifest Builder - LS Artwork Fix
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build_Manifest_Fast_LSArtwork_FIX.ps1"
set "EC=%ERRORLEVEL%"
echo.
if not "%EC%"=="0" echo Builder gagal.
pause
exit /b %EC%

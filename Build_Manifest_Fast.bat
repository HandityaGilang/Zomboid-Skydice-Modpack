@echo off
setlocal
cd /d "%~dp0"
title Skydice Manifest Builder FAST
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build_Manifest_Fast.ps1"
set "EC=%ERRORLEVEL%"
echo.
if not "%EC%"=="0" echo Builder gagal. Cek pesan di atas.
pause
exit /b %EC%

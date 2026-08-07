@echo off
setlocal
cd /d "%~dp0"
title Skydice Manifest Builder v2.0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build_Manifest_Fast.ps1"
echo.
pause

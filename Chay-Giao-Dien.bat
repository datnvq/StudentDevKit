@echo off
chcp 65001 >nul
title StudentDevKit v0.4.1 - Giao Diện Đồ Họa

:: Kiểm tra quyền Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [THÔNG BÁO] Đang yêu cầu quyền Administrator (UAC)...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -Gui

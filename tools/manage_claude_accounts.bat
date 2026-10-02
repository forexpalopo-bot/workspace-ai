@echo off
setlocal enabledelayedexpansion
title Multi-Akun Claude Manager (ChromeDebug)

:MENU
cls
echo ================================================================
echo       MULTI-AKUN CLAUDE MANAGER - KOORDINATOR ANTIGRAVITY       
echo ================================================================
echo.
echo Profil Browser : ChromeDebug (Port 9222)
echo Mode           : Multi-Tab Terisolasi (1 Browser, Banyak Akun)
echo.
echo [1] Buka Tab Login Akun Claude Baru (Akun ke-2, ke-3, dst.)
echo [2] Periksa Status Semua Tab Akun (Ketersediaan Token ^& Kuota)
echo [3] Pulihkan Sesi Semua Akun Tersimpan
echo [4] Jalankan ChromeDebug (Port 9222)
echo [0] Keluar
echo.
set /p "CHOICE=Pilih menu [0-4]: "

if "%CHOICE%"=="1" (
    call "%~dp0open_new_account_tab.bat"
    goto MENU
)

if "%CHOICE%"=="2" (
    echo.
    echo [INFO] Memeriksa status tab akun Claude...
    node "%~dp0claude_multitab_coordinator.cjs" --status
    echo.
    pause
    goto MENU
)

if "%CHOICE%"=="3" (
    echo.
    echo [INFO] Memulihkan seluruh sesi akun tersimpan...
    node "%~dp0restore_claude_accounts.cjs"
    echo.
    pause
    goto MENU
)

if "%CHOICE%"=="4" (
    echo.
    echo [INFO] Menjalankan ChromeDebug...
    call "%~dp0launch_chromedebug.bat"
    goto MENU
)

if "%CHOICE%"=="0" exit /b 0

goto MENU

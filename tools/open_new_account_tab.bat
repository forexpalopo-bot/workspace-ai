@echo off
setlocal enabledelayedexpansion
title Tambah Tab Akun Claude Baru (ChromeDebug)

echo ================================================================
echo           TAMBAH TAB AKUN CLAUDE BARU (CHROMEDEBUG)             
echo ================================================================
echo.
echo Masukkan jumlah tab login baru yang ingin Anda buka:
echo Tekan ENTER langsung untuk membuka 1 tab.
echo.
set /p "COUNT=Jumlah tab [1]: "
if "%COUNT%"=="" set "COUNT=1"

echo.
echo Membuka %COUNT% tab login Claude baru...
node "%~dp0open_new_account_tab.cjs" %COUNT%
echo.
timeout /t 5

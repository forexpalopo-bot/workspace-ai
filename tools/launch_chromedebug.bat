@echo off
setlocal enabledelayedexpansion

echo ================================================================
echo    Chrome Debug Launcher (Profile: ChromeDebug ^| Port: 9222)
echo ================================================================
echo.

set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "USER_DATA_DIR=C:\Users\DELL\ChromeDebug"
set "PORT=9222"
set "TARGET_URL=https://claude.ai/chat/b87a9d83-732b-424b-80ff-d27c8fc2ecc3"

if not exist "%CHROME_EXE%" (
    echo [ERROR] Chrome tidak ditemukan di "%CHROME_EXE%"
    pause
    exit /b 1
)

if not exist "%USER_DATA_DIR%" (
    mkdir "%USER_DATA_DIR%"
)

:: Cek apakah port 9222 sudah aktif mendengarkan
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel! equ 0 (
    echo [INFO] ChromeDebug pada port %PORT% SUDAH AKTIF dan siap!
    echo Membuka URL target di jendela ChromeDebug...
    start "" "%CHROME_EXE%" --user-data-dir="%USER_DATA_DIR%" "%TARGET_URL%"
    timeout /t 2 >nul
    exit /b 0
)

echo Memulai Google Chrome dengan profil khusus: %USER_DATA_DIR%
echo Port debugging: %PORT%
echo Target URL: %TARGET_URL%
echo.

start "" "%CHROME_EXE%" --remote-debugging-port=%PORT% --user-data-dir="%USER_DATA_DIR%" --remote-allow-origins=* "%TARGET_URL%"

echo Menunggu Chrome aktif...
ping 127.0.0.1 -n 4 >nul

powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel! equ 0 (
    echo [SUKSES] ChromeDebug BERHASIL AKTIF di port %PORT%!
    echo Antigravity sekarang dapat membaca dan mengontrol halaman Claude secara otomatis.
) else (
    echo [INFO] Chrome telah dimulai. Silakan periksa jendela browser di layar Anda.
)

echo.
timeout /t 3 >nul
exit /b 0

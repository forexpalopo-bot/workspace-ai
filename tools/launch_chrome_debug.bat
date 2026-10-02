@echo off
setlocal enabledelayedexpansion

echo =======================================================
echo    Google Chrome Launcher (Remote Debugging Port 9222)
echo =======================================================
echo.

set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "PROFILE=Profile 1"
set "PORT=9222"

if not exist "%CHROME_EXE%" (
    echo [ERROR] Chrome executable tidak ditemukan di: "%CHROME_EXE%"
    pause
    exit /b 1
)

:: Cek apakah port 9222 sudah aktif mendengarkan
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel! equ 0 goto port_already_active

:: Cek apakah proses chrome.exe sedang berjalan
tasklist /FI "IMAGENAME eq chrome.exe" 2>nul | find /I "chrome.exe" >nul 2>&1
if !errorlevel! equ 0 goto chrome_running_without_port

goto do_launch

:port_already_active
echo [INFO] Remote debugging port %PORT% sudah AKTIF!
echo Membuka jendela Chrome (Profile: %PROFILE%)...
start "" "%CHROME_EXE%" --remote-debugging-port=%PORT% --profile-directory="%PROFILE%"
echo Selesai.
ping 127.0.0.1 -n 3 >nul
exit /b 0

:chrome_running_without_port
echo [PERHATIAN] Google Chrome sedang berjalan TANPA remote debugging port %PORT%.
echo Chrome HANYA bisa membuka port %PORT% jika proses utama dimulai dari awal.
echo.
if "%~1"=="--force" goto do_restart
if "%~1"=="-f" goto do_restart
if "%~1"=="--restart" goto do_restart
if "%~1"=="-r" goto do_restart

echo Pilih opsi:
echo  [1] Restart Chrome sekarang (tutup lalu buka ulang dengan port %PORT%, tab dipulihkan)
echo  [2] Buka jendela baru saja (CATATAN: port %PORT% tetap tidak aktif)
echo  [3] Batal
echo.
set /p "OPT=Masukkan pilihan (1/2/3) [default: 1]: "
if "!OPT!"=="" set "OPT=1"

if "!OPT!"=="1" goto do_restart
if "!OPT!"=="2" goto do_open_existing
if "!OPT!"=="3" goto do_cancel

goto do_restart

:do_cancel
echo Dibatalkan oleh pengguna.
exit /b 0

:do_restart
echo.
echo Menutup semua proses Chrome...
taskkill /F /IM chrome.exe >nul 2>&1
ping 127.0.0.1 -n 3 >nul
goto do_launch

:do_open_existing
start "" "%CHROME_EXE%" --profile-directory="%PROFILE%"
exit /b 0

:do_launch
echo Memulai Google Chrome dengan remote debugging port %PORT% (Profile: %PROFILE%)...
start "" "%CHROME_EXE%" --remote-debugging-port=%PORT% --profile-directory="%PROFILE%"

:: Tunggu 3 detik dan verifikasi port
ping 127.0.0.1 -n 4 >nul
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel! equ 0 (
    echo [SUKSES] Google Chrome berhasil aktif dengan remote debugging di port %PORT%!
) else (
    echo [INFO] Google Chrome telah dijalankan.
)

echo.
ping 127.0.0.1 -n 3 >nul
exit /b 0

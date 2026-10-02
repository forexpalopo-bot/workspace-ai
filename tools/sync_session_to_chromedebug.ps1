Write-Host "=== 1. Terminating ONLY ChromeDebug processes ==="
Get-CimInstance Win32_Process -Filter "name = 'chrome.exe'" | Where-Object { $_.CommandLine -like "*ChromeDebug*" } | ForEach-Object {
    Write-Host "Stopping ChromeDebug PID $($_.ProcessId)..."
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

$srcUserData = "C:\Users\DELL\AppData\Local\Google\Chrome\User Data"
$srcProfile = Join-Path $srcUserData "Profile 1"
$dstUserData = "C:\Users\DELL\ChromeDebug"
$dstDefault = Join-Path $dstUserData "Default"
$dstProfile1 = Join-Path $dstUserData "Profile 1"

Write-Host "=== 2. Copying Local State (Master encryption key) ==="
Copy-Item (Join-Path $srcUserData "Local State") (Join-Path $dstUserData "Local State") -Force
Write-Host "Local State copied successfully."

Write-Host "=== 3. Syncing Profile data to ChromeDebug\Default ==="
if (-not (Test-Path $dstDefault)) { New-Item -ItemType Directory -Path $dstDefault -Force | Out-Null }
if (-not (Test-Path $dstProfile1)) { New-Item -ItemType Directory -Path $dstProfile1 -Force | Out-Null }

# Robocopy options: /E (recursive), /XF (exclude files), /XD (exclude directories), /R:1 /W:1 (retry once)
$excludeDirs = @("Cache", "Code Cache", "GPUCache", "DawnCache", "Service Worker", "blob_storage", "Crashpad")
$excludeArgs = $excludeDirs | ForEach-Object { "/XD `"$($_)`"" }

Write-Host "Copying to ChromeDebug\Default..."
robocopy "$srcProfile" "$dstDefault" /E /XD Cache "Code Cache" GPUCache DawnCache "Service Worker" blob_storage Crashpad /R:1 /W:1 /NJH /NJS /NDL /NC /NS

Write-Host "Copying to ChromeDebug\Profile 1..."
robocopy "$srcProfile" "$dstProfile1" /E /XD Cache "Code Cache" GPUCache DawnCache "Service Worker" blob_storage Crashpad /R:1 /W:1 /NJH /NJS /NDL /NC /NS

Write-Host "=== 4. Launching ChromeDebug with remote debugging ==="
$shortcut = "C:\Users\DELL\Desktop\Chrome Debug (Claude).lnk"
Start-Process "explorer.exe" -ArgumentList "`"$shortcut`""
Write-Host "Launched via Explorer shortcut. Waiting for port 9222..."

$connected = $false
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 1
    $conn = Get-NetTCPConnection -LocalPort 9222 -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $connected = $true
        Write-Host "SUCCESS: ChromeDebug is listening on port 9222 (PID: $($conn.OwningProcess))!"
        break
    }
}

if (-not $connected) {
    Write-Warning "Port 9222 did not respond in time."
}

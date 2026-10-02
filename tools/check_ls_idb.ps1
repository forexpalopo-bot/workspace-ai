$profPath = 'C:\Users\DELL\AppData\Local\Google\Chrome\User Data\Profile 1'
$lsPath = Join-Path $profPath "Local Storage"
$idbPath = Join-Path $profPath "IndexedDB"

Write-Host "Local Storage files:"
Get-ChildItem -Recurse $lsPath | Select-Object -First 5 | ForEach-Object { Write-Host " - $($_.FullName)" }

Write-Host "IndexedDB files:"
Get-ChildItem -Recurse $idbPath | Where-Object { $_.FullName -like "*claude*" } | Select-Object -First 5 | ForEach-Object { Write-Host " - $($_.FullName)" }

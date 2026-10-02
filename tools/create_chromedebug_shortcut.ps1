$wsh = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Chrome Debug (Claude).lnk"

$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$shortcut.Arguments = '--remote-debugging-port=9222 --user-data-dir="C:\Users\DELL\ChromeDebug" --remote-allow-origins=* https://claude.ai/chat/b87a9d83-732b-424b-80ff-d27c8fc2ecc3'
$shortcut.WorkingDirectory = "C:\Program Files\Google\Chrome\Application"
$shortcut.IconLocation = "C:\Program Files\Google\Chrome\Application\chrome.exe,0"
$shortcut.Description = "Dedicated Chrome Debug Profile for Claude Automation (Port 9222)"
$shortcut.Save()

Write-Host "Created shortcut: $shortcutPath"
Write-Host "Target: $($shortcut.TargetPath)"
Write-Host "Arguments: $($shortcut.Arguments)"

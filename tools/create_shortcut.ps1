$wsh = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Google Chrome (Debug 9222).lnk"

$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$shortcut.Arguments = '--remote-debugging-port=9222 --profile-directory="Profile 1"'
$shortcut.WorkingDirectory = "C:\Program Files\Google\Chrome\Application"
$shortcut.IconLocation = "C:\Program Files\Google\Chrome\Application\chrome.exe,0"
$shortcut.Description = "Google Chrome with Remote Debugging port 9222 (Profile 1)"
$shortcut.Save()

Write-Host "Shortcut created successfully at: $shortcutPath"
Write-Host "Target: $($shortcut.TargetPath)"
Write-Host "Arguments: $($shortcut.Arguments)"
Write-Host "Working Directory: $($shortcut.WorkingDirectory)"


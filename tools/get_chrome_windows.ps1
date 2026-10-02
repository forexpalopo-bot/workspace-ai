Get-Process chrome | Where-Object { $_.MainWindowTitle } | Select-Object Id, MainWindowTitle | Format-Table -AutoSize

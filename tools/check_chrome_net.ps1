$pids = (Get-Process chrome).Id
Get-NetTCPConnection | Where-Object { $pids -contains $_.OwningProcess } | Select-Object OwningProcess, LocalAddress, LocalPort, State | Format-Table -AutoSize

$targets = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json"
Write-Host "Target count: $($targets.Count)"
foreach ($t in $targets) {
    Write-Host "[$($t.type)] $($t.title) -> $($t.url)"
}

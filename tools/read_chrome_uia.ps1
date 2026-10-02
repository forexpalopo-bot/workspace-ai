Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$condition = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Window
)

$windows = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
    [System.Windows.Automation.TreeScope]::Children,
    $condition
)

Write-Host "Found $($windows.Count) top-level windows."

$chromeWindow = $null
foreach ($win in $windows) {
    try {
        $name = $win.Current.Name
        if ($name -like "*Claude*" -or $name -like "*Chrome*") {
            Write-Host "Matched window: $name (ProcessId: $($win.Current.ProcessId))"
            $chromeWindow = $win
            break
        }
    } catch {}
}

if (-not $chromeWindow) {
    Write-Host "No Chrome/Claude window found in top-level windows."
} else {
    Write-Host "Searching for document elements inside Chrome window..."
    $docCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Document
    )
    $docs = $chromeWindow.FindAll([System.Windows.Automation.TreeScope]::Descendants, $docCondition)
    Write-Host "Found $($docs.Count) Document elements."
    foreach ($doc in $docs) {
        Write-Host "Doc Name: $($doc.Current.Name)"
    }
}

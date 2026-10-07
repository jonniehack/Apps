$Product = 'VisioProRetail'

If (Test-Path HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration) {
    $Installed = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration -Name ProductReleaseIds
    If ($Installed -match $Product) {
        Write-Host "Installed"
        Exit 0
    }
    Else {
        Write-Host "Not Installed"
        Exit 1
    }
}
Else {
    Write-Host "Not Installed"
    Exit 1
}
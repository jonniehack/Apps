# CMTrace uninstallation
$ErrorActionPreference = 'Stop'
try {
    $Destination = Join-Path $env:windir 'System32\cmtrace.exe'
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        Remove-Item -LiteralPath $Destination -Force
    }
    if (Test-Path -LiteralPath $Destination -PathType Leaf) { throw "Removal verification failed: $Destination" }
    Write-Output "CMTrace removed: $Destination"
    exit 0
}
catch {
    Write-Error "CMTrace uninstallation failed: $($_.Exception.Message)"
    exit 1
}

# CMTrace installation
$ErrorActionPreference = 'Stop'
try {
    $Source = Join-Path $PSScriptRoot 'cmtrace.exe'
    $Destination = Join-Path $env:windir 'System32\cmtrace.exe'
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Source executable not found: $Source" }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) { throw "Installation verification failed: $Destination" }
    Write-Output "CMTrace installed: $Destination"
    exit 0
}
catch {
    Write-Error "CMTrace installation failed: $($_.Exception.Message)"
    exit 1
}

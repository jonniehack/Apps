<#
.SYNOPSIS
    Downloads the latest Microsoft Office Deployment Tool (ODT).

.DESCRIPTION
    Downloads the latest Office Deployment Tool from Microsoft, extracts
    setup.exe, validates its digital signature and updates the copy held
    in the package Files directory when required.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Paths
$FilesPath   = Join-Path $PSScriptRoot 'Files'
$SetupPath   = Join-Path $FilesPath 'setup.exe'
$TempPath    = Join-Path $env:TEMP 'OfficeDeploymentTool'
$ExtractPath = Join-Path $TempPath 'Extracted'
$ODTDownload = Join-Path $TempPath 'OfficeDeploymentTool.exe'

# Microsoft Office Deployment Tool download page
$ODTDownloadPage = 'https://www.microsoft.com/en-us/download/details.aspx?id=49117'

try {

    Write-Host 'Checking for the latest Office Deployment Tool...'

    # Clean temporary working directory
    if (Test-Path $TempPath) {
        Remove-Item -Path $TempPath -Recurse -Force
    }

    New-Item -Path $TempPath -ItemType Directory -Force | Out-Null
    New-Item -Path $ExtractPath -ItemType Directory -Force | Out-Null

    # Get the current ODT download URL from Microsoft
    $DownloadPage = Invoke-WebRequest `
        -Uri $ODTDownloadPage `
        -UseBasicParsing

    $ODTUrl = $DownloadPage.Links |
        Where-Object {
            $_.href -like '*officedeploymenttool*.exe*'
        } |
        Select-Object -First 1 -ExpandProperty href

    if (-not $ODTUrl) {
        throw 'Unable to determine the Office Deployment Tool download URL.'
    }

    Write-Host "Downloading: $ODTUrl"

    # Download the ODT self-extracting executable
    Invoke-WebRequest `
        -Uri $ODTUrl `
        -OutFile $ODTDownload `
        -UseBasicParsing

    # Validate the downloaded package
    $Signature = Get-AuthenticodeSignature -FilePath $ODTDownload

    if ($Signature.Status -ne 'Valid') {
        throw "Office Deployment Tool download has an invalid digital signature: $($Signature.Status)"
    }

    if ($Signature.SignerCertificate.Subject -notlike '*Microsoft Corporation*') {
        throw "Office Deployment Tool download is not signed by Microsoft Corporation."
    }

    Write-Host 'Microsoft digital signature verified.'

    # Extract setup.exe
    Write-Host 'Extracting Office Deployment Tool...'

    $Process = Start-Process `
        -FilePath $ODTDownload `
        -ArgumentList "/quiet /extract:`"$ExtractPath`"" `
        -Wait `
        -PassThru

    if ($Process.ExitCode -ne 0) {
        throw "Office Deployment Tool extraction failed with exit code $($Process.ExitCode)."
    }

    $ExtractedSetup = Join-Path $ExtractPath 'setup.exe'

    if (-not (Test-Path $ExtractedSetup)) {
        throw 'setup.exe was not found after extracting the Office Deployment Tool.'
    }

    # Validate extracted setup.exe
    $Signature = Get-AuthenticodeSignature -FilePath $ExtractedSetup

    if ($Signature.Status -ne 'Valid') {
        throw "Extracted setup.exe has an invalid digital signature: $($Signature.Status)"
    }

    if ($Signature.SignerCertificate.Subject -notlike '*Microsoft Corporation*') {
        throw 'Extracted setup.exe is not signed by Microsoft Corporation.'
    }

    # Get latest version
    $LatestVersion = [Version](Get-Item $ExtractedSetup).VersionInfo.FileVersion

    Write-Host "Latest ODT version:    $LatestVersion"

    # Create Files directory if required
    if (-not (Test-Path $FilesPath)) {
        New-Item -Path $FilesPath -ItemType Directory -Force | Out-Null
    }

    # Compare against existing setup.exe
    if (Test-Path $SetupPath) {

        $CurrentVersion = [Version](Get-Item $SetupPath).VersionInfo.FileVersion

        Write-Host "Packaged ODT version:  $CurrentVersion"

        if ($LatestVersion -gt $CurrentVersion) {

            Write-Host 'A newer Office Deployment Tool is available.'

            Copy-Item `
                -Path $ExtractedSetup `
                -Destination $SetupPath `
                -Force

            Write-Host "Updated setup.exe to version $LatestVersion."
        }
        elseif ($LatestVersion -eq $CurrentVersion) {

            Write-Host 'The packaged Office Deployment Tool is already current.'
        }
        else {

            Write-Warning "The downloaded ODT ($LatestVersion) is older than the packaged version ($CurrentVersion)."
            Write-Warning 'setup.exe has not been replaced.'
        }
    }
    else {

        Write-Host 'No existing setup.exe found.'

        Copy-Item `
            -Path $ExtractedSetup `
            -Destination $SetupPath `
            -Force

        Write-Host "Added Office Deployment Tool version $LatestVersion."
    }
}
catch {

    Write-Error "Failed to update Office Deployment Tool: $($_.Exception.Message)"
    exit 1
}
finally {

    # Remove temporary files
    if (Test-Path $TempPath) {
        Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
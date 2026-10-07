<#

.SYNOPSIS
PSAppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION
- The script is provided as a template to perform an install, uninstall, or repair of an application(s).
- The script either performs an "Install", "Uninstall", or "Repair" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script imports the PSAppDeployToolkit module which contains the logic and functions required to install or uninstall an application.

PSAppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2025 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Mitch Richters, Dan Gough).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType
The type of deployment to perform.

.PARAMETER DeployMode
Specifies whether the installation should be run in Interactive (shows dialogs), Silent (no dialogs), or NonInteractive (dialogs without prompts) mode.

NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru
Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode
Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging
Disables logging to file for the script.

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeployMode Silent

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -AllowRebootPassThru

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall

.EXAMPLE
Invoke-AppDeployToolkit.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS
None. You cannot pipe objects to this script.

.OUTPUTS
None. This script does not generate any output.

.NOTES
Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Invoke-AppDeployToolkit.ps1, and Invoke-AppDeployToolkit.exe
- 69000 - 69999: Recommended for user customized exit codes in Invoke-AppDeployToolkit.ps1
- 70000 - 79999: Recommended for user customized exit codes in PSAppDeployToolkit.Extensions module.

.LINK
https://psappdeploytoolkit.com

#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [PSDefaultValue(Help = 'Install', Value = 'Install')]
    [System.String]$DeploymentType,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [PSDefaultValue(Help = 'Interactive', Value = 'Interactive')]
    [System.String]$DeployMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$AllowRebootPassThru,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$TerminalServerMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$DisableLogging,

    [Parameter(Mandatory = $false)]
    [ValidateSet(
        '365-Current-NoTeams',
        '365-Current-NoTeams-SPC',
        '365-Current-WithTeams',
        '365-Current-WithTeams-SPC',
        '365-MonthlyEnterprise-NoTeams',
        '365-MonthlyEnterprise-NoTeams-SPC',
        '365-MonthlyEnterprise-WithTeams',
        '365-MonthlyEnterprise-WithTeams-SPC',
        '365-MonthlyEnterprise-WithTeams-x86',
        '365-SemiAnnual-NoTeams',
        '365-SemiAnnual-NoTeams-SPC',
        '365-SemiAnnual-WithTeams',
        '365-SemiAnnual-WithTeams-SPC',
        '365-VisioPlan2',
        '365-ProjectPlan3'
    )]
    [System.String]$Version
)


##================================================
## MARK: Variables
##================================================

$adtSession = @{
    # App variables.
    AppVendor = 'Microsoft'
    AppName = '365 Apps for Enterprise'
    AppVersion = '365'
    AppArch = 'x64'
    AppLang = 'EN'
    AppRevision = '01'
    AppSuccessExitCodes = @(0)
    AppRebootExitCodes = @(1641, 3010)
    AppScriptVersion = '1.0.5'
    AppScriptDate = '2025-07-18'
    AppScriptAuthor = 'Jonathan Fallis'

    # Script variables.
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptVersion = '4.0.6'
    DeployAppScriptParameters = $PSBoundParameters
}


function Install-ADTDeployment
{
    ##================================================
    ## MARK: Pre-Install
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt.
    Show-ADTInstallationWelcome -CloseProcesses 'excel,onenote,outlook,mspub,powerpnt,winword,teams,visio,winproj' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress

    ## <Perform Pre-Installation tasks here>


    ##================================================
    ## MARK: Install
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI installations.
    if ($adtSession.UseDefaultMsi)
    {
        $ExecuteDefaultMSISplat = @{
            Action   = $adtSession.DeploymentType
            FilePath = $adtSession.DefaultMsiFile
        }

        if ($adtSession.DefaultMstFile)
        {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }

        Start-ADTMsiProcess @ExecuteDefaultMSISplat

        if ($adtSession.DefaultMspFiles)
        {
            $adtSession.DefaultMspFiles | Start-ADTMsiProcess -Action Patch
        }
    }


    ## <Perform Installation tasks here>

    # Select the Microsoft 365 configuration file based on the Version parameter.
    # If no Version is specified, default to 365-Current-WithTeams 64 bit.
    #
    ###############################################################################
    #     WARNING! Create separate apps for Project Plan 3 or Visio Plan 2.       #
    #     WARNING! If customer has Autopatch you MUST use MONTHLY ENTERPRISE      #
    ###############################################################################

    switch ($Version) {
        '365-Current-NoTeams'                 { $ConfigurationFile = '365-Current-NoTeams.xml' }
        '365-Current-NoTeams-SPC'             { $ConfigurationFile = '365-Current-NoTeams-SPC.xml' }
        '365-Current-WithTeams'               { $ConfigurationFile = '365-Current-WithTeams.xml' }
        '365-Current-WithTeams-SPC'           { $ConfigurationFile = '365-Current-WithTeams-SPC.xml' }
        '365-MonthlyEnterprise-NoTeams'       { $ConfigurationFile = '365-MonthlyEnterprise-NoTeams.xml' }
        '365-MonthlyEnterprise-NoTeams-SPC'   { $ConfigurationFile = '365-MonthlyEnterprise-NoTeams-SPC.xml' }
        '365-MonthlyEnterprise-WithTeams'     { $ConfigurationFile = '365-MonthlyEnterprise-WithTeams.xml' }
        '365-MonthlyEnterprise-WithTeams-SPC' { $ConfigurationFile = '365-MonthlyEnterprise-WithTeams-SPC.xml' }
        '365-SemiAnnual-NoTeams'              { $ConfigurationFile = '365-SemiAnnual-NoTeams.xml' }
        '365-SemiAnnual-NoTeams-SPC'          { $ConfigurationFile = '365-SemiAnnual-NoTeams-SPC.xml' }
        '365-SemiAnnual-WithTeams'            { $ConfigurationFile = '365-SemiAnnual-WithTeams.xml' }
        '365-SemiAnnual-WithTeams-SPC'        { $ConfigurationFile = '365-SemiAnnual-WithTeams-SPC.xml' }
        '365-VisioPlan2'                      { $ConfigurationFile = '365-VisioPlan2.xml' }
        '365-ProjectPlan3'                    { $ConfigurationFile = '365-ProjectPlan3.xml' }

        # No Version selected - default to Current Channel with Teams.
        default                               { $ConfigurationFile = '365-Current-WithTeams.xml' }
    }


    # Pre-Install Clean up.
    # Not necessary for Visio or Project

    if ($Version -notin @(
        '365-VisioPlan2',
        '365-ProjectPlan3'
    )) 
    {

        # Discover existing Microsoft Office Click-to-Run products.
        $OfficeUninstallPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'

        $OfficeC2RProducts = Get-ChildItem -Path $OfficeUninstallPath -ErrorAction SilentlyContinue |
            ForEach-Object {

                $Product = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue

                if (
                    $Product.ClickToRunComponent -eq 1 -and
                    $Product.UninstallString -and
                    $Product.UninstallString -like '*OfficeClickToRun.exe*productstoremove=*'
                )
                {
                    [PSCustomObject]@{
                        DisplayName     = $Product.DisplayName
                        RegistryName    = $_.PSChildName
                        UninstallString = $Product.UninstallString
                    }
                }
            }


        # Remove each discovered Click-to-Run product using its registered uninstall command.
        $OfficeClickToRun = 'C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe'

        foreach ($OfficeProduct in $OfficeC2RProducts) {

            Write-ADTLogEntry -Message "Removing Office Click-to-Run product: [$($OfficeProduct.DisplayName)]"

            $Arguments = $OfficeProduct.UninstallString.Split('"', 3)[2].Trim()
            $Arguments = "$Arguments displaylevel=False"

            Write-ADTLogEntry -Message "Command: [$OfficeClickToRun $Arguments]"

            Start-ADTProcess -FilePath $OfficeClickToRun -ArgumentList $Arguments
        }


        # Enable verbose Microsoft 365 Click-to-Run logging.
        Set-ADTRegistryKey -Key 'HKLM\SOFTWARE\Microsoft\ClickToRun\OverRide' -Name 'LogLevel' -Type 'DWord' -Value 3

        Write-ADTLogEntry -Message "Removing Office Click-to-Run products and setting verbose logging, completed"

    } # Pre-Install


    # Install Microsoft 365 Apps using the selected configuration.
    Start-ADTProcess -FilePath 'setup.exe' -ArgumentList "/Configure $ConfigurationFile" -WorkingDirectory $adtSession.DirFiles


    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Installation tasks here>


    ## Display a message at the end of the install.
    if (!$adtSession.UseDefaultMsi)
    {
        Show-ADTInstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait
    }
}


function Uninstall-ADTDeployment
{
    ##================================================
    ## MARK: Pre-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing.
    Show-ADTInstallationWelcome -CloseProcesses iexplore -CloseProcessesCountdown 60

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress

    ## <Perform Pre-Uninstallation tasks here>


    ##================================================
    ## MARK: Uninstall
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI uninstallations.
    if ($adtSession.UseDefaultMsi)
    {
        $ExecuteDefaultMSISplat = @{
            Action   = $adtSession.DeploymentType
            FilePath = $adtSession.DefaultMsiFile
        }

        if ($adtSession.DefaultMstFile)
        {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }

        Start-ADTMsiProcess @ExecuteDefaultMSISplat
    }


    ## <Perform Uninstallation tasks here>

    if ($Version -like '*visio*') {
        Start-ADTProcess -FilePath 'setup.exe' -ArgumentList '/Configure 365-Visio-Removal.xml' -WorkingDirectory $adtSession.DirFiles
    }
    elseif ($Version -like '*project*') {
        Start-ADTProcess -FilePath 'setup.exe' -ArgumentList '/Configure 365-Project-Removal.xml' -WorkingDirectory $adtSession.DirFiles
    }
    else {
        Start-ADTProcess -FilePath 'setup.exe' -ArgumentList '/Configure 365-Removal.xml' -WorkingDirectory $adtSession.DirFiles
    }


    ##================================================
    ## MARK: Post-Uninstallation
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Uninstallation tasks here>
}


function Repair-ADTDeployment
{
    ##================================================
    ## MARK: Pre-Repair
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing.
    Show-ADTInstallationWelcome -CloseProcesses iexplore -CloseProcessesCountdown 60

    ## Show Progress Message (with the default message).
    Show-ADTInstallationProgress

    ## <Perform Pre-Repair tasks here>


    ##================================================
    ## MARK: Repair
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Handle Zero-Config MSI repairs.
    if ($adtSession.UseDefaultMsi)
    {
        $ExecuteDefaultMSISplat = @{
            Action   = $adtSession.DeploymentType
            FilePath = $adtSession.DefaultMsiFile
        }

        if ($adtSession.DefaultMstFile)
        {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }

        Start-ADTMsiProcess @ExecuteDefaultMSISplat
    }


    ## <Perform Repair tasks here>


    ##================================================
    ## MARK: Post-Repair
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## <Perform Post-Repair tasks here>
}


##================================================
## MARK: Initialization
##================================================

# Set strict error handling across entire operation.
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
Set-StrictMode -Version 1


# Import the module and instantiate a new session.
try
{
    $moduleName = if ([System.IO.File]::Exists("$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"))
    {
        Get-ChildItem -LiteralPath $PSScriptRoot\PSAppDeployToolkit -Recurse -File | Unblock-File -ErrorAction Ignore
        "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"
    }
    else
    {
        'PSAppDeployToolkit'
    }

    Import-Module -FullyQualifiedName @{
        ModuleName    = $moduleName
        Guid          = '8c3c366b-8606-4576-9f2d-4051144f7ca2'
        ModuleVersion = '4.0.6'
    } -Force

    try
    {
        $iadtParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation
        $adtSession = Open-ADTSession -SessionState $ExecutionContext.SessionState @adtSession @iadtParams -PassThru
    }
    catch
    {
        Remove-Module -Name PSAppDeployToolkit* -Force
        throw
    }
}
catch
{
    $Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([System.Int32]::MaxValue)))
    exit 60008
}


##================================================
## MARK: Invocation
##================================================

try
{
    Get-Item -Path $PSScriptRoot\PSAppDeployToolkit.* | & {
        process
        {
            Get-ChildItem -LiteralPath $_.FullName -Recurse -File | Unblock-File -ErrorAction Ignore
            Import-Module -Name $_.FullName -Force
        }
    }

    & "$($adtSession.DeploymentType)-ADTDeployment"

    Close-ADTSession
}
catch
{
    Write-ADTLogEntry -Message ($mainErrorMessage = Resolve-ADTErrorRecord -ErrorRecord $_) -Severity 3
    Show-ADTDialogBox -Text $mainErrorMessage -Icon Stop | Out-Null
    Close-ADTSession -ExitCode 60001
}
finally
{
    Remove-Module -Name PSAppDeployToolkit* -Force
}
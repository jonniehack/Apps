# Microsoft 365 Apps - PSADT Deployment

Microsoft 365 Apps deployment package using **PowerShell App Deployment Toolkit (PSADT) v4.18** and the Microsoft Office Deployment Tool (ODT).

A single deployment script, `Deploy-M365Apps.ps1`, is used to install and remove:

- Microsoft 365 Apps for Enterprise
- Microsoft Visio Plan 2
- Microsoft Project Plan 3

The required configuration is selected using the `-Version` parameter. If `-Version` is not specified for an installation, the default is `365-Current-WithTeams`.

## Package Structure

- `Deploy-M365Apps.ps1` - Main PSADT deployment script
- `Update-OfficeODT.ps1` - Updates the Office Deployment Tool
- `Files\setup.exe` - Microsoft Office Deployment Tool
- `Files\*.xml` - Microsoft 365, Visio and Project configuration files
- `Files\Detection-*.ps1` - Intune detection scripts

## Update the Office Deployment Tool

Before packaging the application, run:

```powershell
.\Update-OfficeODT.ps1
```

This downloads the current Office Deployment Tool and updates `Files\setup.exe`.

## Microsoft 365 Apps Version Naming

```text
365-<Channel>-<Teams>[-SPC][-x86]
```

| Component | Values |
|---|---|
| Product | `365` |
| Update Channel | `Current`, `MonthlyEnterprise`, `SemiAnnual` |
| Teams | `WithTeams`, `NoTeams` |
| Shared PC Mode | `SPC` |

64-bit is the standard architecture and does not require an architecture suffix. No support for x86 versions (yet)

## Supported Versions

### Microsoft 365 Apps

```text
365-Current-NoTeams
365-Current-NoTeams-SPC
365-Current-WithTeams
365-Current-WithTeams-SPC

365-MonthlyEnterprise-NoTeams
365-MonthlyEnterprise-NoTeams-SPC
365-MonthlyEnterprise-WithTeams
365-MonthlyEnterprise-WithTeams-SPC

365-SemiAnnual-NoTeams
365-SemiAnnual-NoTeams-SPC
365-SemiAnnual-WithTeams
365-SemiAnnual-WithTeams-SPC
```

### Visio and Project

```text
365-VisioPlan2
365-ProjectPlan3
```

## Installation

### Microsoft 365 Apps

Current Channel with Teams:

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent -Version "365-Current-WithTeams"
```

Monthly Enterprise without Teams:

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent -Version "365-MonthlyEnterprise-NoTeams"
```

Monthly Enterprise without Teams in Shared PC mode:

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent -Version "365-MonthlyEnterprise-NoTeams-SPC"
```

If `-Version` is omitted, installation defaults to `365-Current-WithTeams`:

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent
```

### Visio Plan 2

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent -Version "365-VisioPlan2"
```

Uses `Files\365-VisioPlan2.xml` with:

- `VisioProRetail`
- 64-bit architecture
- `Version="MatchInstalled"`
- `en-us` language

### Project Plan 3

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent -Version "365-ProjectPlan3"
```

Uses `Files\365-ProjectPlan3.xml` with:

- `ProjectProRetail`
- 64-bit architecture
- `Version="MatchInstalled"`
- `en-us` language

## Uninstall

### Microsoft 365 Apps

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Uninstall -DeployMode Silent
```

Uses `Files\365-Removal.xml`.

### Visio Plan 2

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Uninstall -DeployMode Silent -Version "365-VisioPlan2"
```

Uses `Files\365-Visio-Removal.xml`.

### Project Plan 3

```powershell
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Uninstall -DeployMode Silent -Version "365-ProjectPlan3"
```

Uses `Files\365-Project-Removal.xml`.

## Intune Win32 App Commands

### Microsoft 365 Apps

**Install**

```text
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent -Version "365-Current-WithTeams"
```

**Uninstall**

```text
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Uninstall -DeployMode Silent
```

### Visio Plan 2

**Install**

```text
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent -Version "365-VisioPlan2"
```

**Uninstall**

```text
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Uninstall -DeployMode Silent -Version "365-VisioPlan2"
```

### Project Plan 3

**Install**

```text
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Install -DeployMode Silent -Version "365-ProjectPlan3"
```

**Uninstall**

```text
Invoke-AppDeployToolkit.exe Deploy-M365Apps.ps1 -DeploymentType Uninstall -DeployMode Silent -Version "365-ProjectPlan3"
```

## Intune Detection

Use the appropriate PowerShell detection script from the `Files` folder as the custom detection script for each Intune Win32 application.

Detection is based on the Click-to-Run `ProductReleaseIds` value.

| Application | Product ID |
|---|---|
| Microsoft 365 Apps | `O365ProPlusRetail` |
| Visio Plan 2 | `VisioProRetail` |
| Project Plan 3 | `ProjectProRetail` |

## Configuration Files

Each supported `-Version` value maps to an XML configuration file in the `Files` folder.

```text
365-Current-WithTeams
    -> Files\365-Current-WithTeams.xml

365-MonthlyEnterprise-NoTeams-SPC
    -> Files\365-MonthlyEnterprise-NoTeams-SPC.xml

365-SemiAnnual-WithTeams
    -> Files\365-SemiAnnual-WithTeams.xml

365-VisioPlan2
    -> Files\365-VisioPlan2.xml

365-ProjectPlan3
    -> Files\365-ProjectPlan3.xml
```

## Adding Additional Configurations

Additional configurations can be created using the [Microsoft Office Customization Tool](https://config.office.com/deploymentsettings).

When adding a configuration:

- Add the XML file to the `Files` folder.
- Add the corresponding value to the `-Version` parameter `ValidateSet`.
- Add the configuration to the version selection logic in `Deploy-M365Apps.ps1`.
- Ensure the architecture is compatible with the installed Microsoft 365 Apps architecture.
- Look at the other configuration files to align to whats already created
- Ensure the selected product is appropriately licensed.

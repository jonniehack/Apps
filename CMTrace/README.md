# CMTrace

<img src="/_Icons/SystemCentre.png" alt="System Center logo" width="96">

**CMTrace** is Microsoft's log viewer distributed with Microsoft Configuration Manager (ConfigMgr). It makes Configuration Manager and other text-based logs easier to read, including highlighting errors and warnings.

This folder provides the standalone executable and separate PowerShell scripts for installation and uninstallation, suitable for packaging as a Microsoft Intune Win32 app.

## Source and version

| Property | Details |
| --- | --- |
| Application | CMTrace |
| Source | Tools folder of a Microsoft Configuration Manager installation |
| ConfigMgr release | 2403 |
| File version | `5.0.9128.1007` |
| Installed executable | `C:\Windows\System32\cmtrace.exe` |
| Installation method | Copy the executable; no MSI required |

The executable is a Microsoft utility. This repository provides deployment resources, not the application's source code.

## Package files

| File | Purpose |
| --- | --- |
| `cmtrace.exe` | Executable obtained from ConfigMgr 2403 |
| `CMTraceInstall.ps1` | Copies the executable into System32 |
| `CMTraceUninstall.ps1` | Removes the executable from System32 |

The logo is for the Intune app listing and README; it is not required in the Win32 installation package.

## Installation

The [installation script](CMTraceInstall.ps1) locates `cmtrace.exe` in the same directory as the script, copies it to `C:\Windows\System32` and checks that the destination exists. It overwrites an existing copy and returns exit code **0** on success or **1** on failure.

Run as administrator in **64-bit PowerShell**:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\CMTraceInstall.ps1
```

## Uninstallation

The [uninstallation script](CMTraceUninstall.ps1) removes `C:\Windows\System32\cmtrace.exe`. It returns success if the file is already absent. Exit code **0** indicates success; **1** indicates failure.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\CMTraceUninstall.ps1
```

> [!NOTE]
> Uninstallation removes the executable at this path regardless of how it was originally installed. Ensure no other deployment relies on that copy.

## Microsoft Intune deployment

Create a **Windows app (Win32)** package containing `cmtrace.exe` and both PowerShell scripts. Use the Microsoft Win32 Content Prep Tool to build the `.intunewin` file.

| Setting | Value |
| --- | --- |
| App type | Windows app (Win32) |
| Install command | `%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\CMTraceInstall.ps1` |
| Uninstall command | `%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\CMTraceUninstall.ps1` |
| Install behaviour | System |
| Device restart behaviour | No specific action |
| Detection rule type | File |
| Detection path | `C:\Windows\System32` |
| File or folder | `cmtrace.exe` |
| Detection method | File or folder exists |
| Associated with a 32-bit app on 64-bit clients | No |

The `Sysnative` path makes Intune's 32-bit execution context launch 64-bit PowerShell, so System32 is not redirected to SysWOW64. The scripts require administrative permissions.

### Optional version-based detection

For version-aware deployments, change the detection method from file presence to **String (version)**:

| Setting | Value |
| --- | --- |
| Path | `C:\Windows\System32` |
| File | `cmtrace.exe` |
| Detection method | String (version) |
| Operator | Greater than or equal to |
| Value | `5.0.9128.1007` |

Use **Equals** instead if you need this exact version. File-presence detection alone cannot tell whether a device has an older release.

## Notes

- The installation script uses `$PSScriptRoot` to locate the source executable, independently of the working directory.
- The executable may need to be closed before it can be overwritten or removed.
- The scripts do not create shortcuts or set file associations.
- The uninstaller removes only `cmtrace.exe` from the specified System32 location.
- For a newer version, obtain the executable from the appropriate Configuration Manager installation and review the detection rule.

## Credits

CMTrace is a Microsoft utility distributed with Microsoft Configuration Manager.

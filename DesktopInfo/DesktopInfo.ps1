# Creates DesktopInfo Folder if it does not exist
$InstallPath = "$Env:ProgramData\DesktopInfo"
if (!(Test-Path -Path $InstallPath)) {
    New-Item $InstallPath -Type Directory -Force
}

# Copies DesktopInfo files to ProgramData\DesktopInfo
Get-ChildItem -Recurse | Where-Object { $_.Extension -ne '.ps1' } | Copy-Item -Destination $InstallPath -Force

# Creates shortcut
$TargetFile = "$InstallPath\DesktopInfo.exe"
$ShortcutFile = "$InstallPath\DesktopInfo.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Copies shortcut to the All Users Startup folder
$CommonStartup = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
Copy-Item "$InstallPath\DesktopInfo.lnk" -Destination $CommonStartup -Force
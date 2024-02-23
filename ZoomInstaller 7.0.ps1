# ZOOM INSTALLER 7.0 
# Enhanced Check using Registry instead of WinGet for Regular and MSI Installations
# This PowerShell script automates the management of Zoom installation on a Windows machine. 
# It includes functions for logging messages, checking if Zoom is installed, removing old versions of Zoom, 
# and downloading and installing the latest version. 
# It handles both regular and MSI installations, updates Zoom if an outdated version is detected, 
# and cleans up temporary files after installation. 
# The script is designed to be robust, with error handling for various steps of the installation and uninstallation process.


$TempZoomPath = "C:\temp_zoom\"

function Log-Message {
    param (
        [String]$Message,
        [String]$Type = "Info"
    )
    switch ($Type) {
        "Info"    { Write-Host "[INFO] $Message" }
        "Error"   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "Success" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
    }
}

function Check-ZoomInstalled {
    $zoomInfo = @{'Installed'=$false; 'Version'=$null; 'Type'=$null}

    # Check for Zoom installation in both HKLM and HKCU
    $pathHKLM = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $pathHKCU = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $zoomRegistryEntries = Get-ItemProperty $pathHKLM, $pathHKCU -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Zoom*" }

    foreach ($entry in $zoomRegistryEntries) {
        if ($entry.DisplayName -like "*Zoom*") {
            $zoomInfo['Installed'] = $true
            $zoomInfo['Version'] = $entry.DisplayVersion
            $zoomInfo['Type'] = 'Regular' # Assume regular unless identified as MSI below
        }
    }

    # Additional logic to determine if the installation is MSI based on specific criteria
    # This is a simplified example, adjust as needed
    if ($zoomInfo['Installed'] -and $zoomRegistryEntries.PSPath -like "*{499EA83F-642D-40CB-A55E-5D385DEDD376}*") {
        $zoomInfo['Type'] = 'MSI'
    }

    return $zoomInfo
}

function Remove-OldZoom {
    try {
        $zipPath = "C:\temp_zoom\CleanZoom.zip"
        $zoomUninstaller = "https://assets.zoom.us/docs/msi-templates/CleanZoom.zip"

        Log-Message -Message "Downloading Zoom uninstaller."
        Invoke-WebRequest -Uri $zoomUninstaller -OutFile $zipPath
        Log-Message -Message "Zoom uninstaller downloaded successfully." -Type "Success"

        Log-Message -Message "Expanding downloaded ZIP folder."
        Expand-Archive -Path $zipPath -DestinationPath $TempZoomPath
        Log-Message -Message "ZIP folder expanded successfully." -Type "Success"

        Log-Message -Message "Starting Zoom uninstaller."
        Start-Process "$TempZoomPath\CleanZoom.exe" -ArgumentList "/silent /keep_outlook_plugin /keep_lync_plugin /keep_notes_plugin" -Wait
        Log-Message -Message "Zoom has been uninstalled." -Type "Success"
    } catch {
        Log-Message -Message "Error during Zoom uninstallation: $_" -Type "Error"
    }
}

function Download-AndInstallZoom {
    try {
        $msiInstallerUrl = "https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64"
        $installerPath = "$TempZoomPath\ZoomInstallerFull.msi"

        Log-Message -Message "Downloading the latest Zoom MSI installer."
        Invoke-WebRequest -Uri $msiInstallerUrl -OutFile $installerPath
        Log-Message -Message "Zoom MSI installer downloaded successfully." -Type "Success"

        Log-Message -Message "Installing Zoom for all users."
        Start-Process "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn /norestart /log `"$TempZoomPath\zoom_msi_install.log`"" -Wait
        Log-Message -Message "Zoom installed successfully for all users." -Type "Success"
    } catch {
        Log-Message -Message "Error during Zoom MSI download/installation: $_" -Type "Error"
    }
}

try {
    if (Test-Path $TempZoomPath) {
        Log-Message -Message "Found path from previous Zoom install script. Deleting folders."
        Remove-Item $TempZoomPath -Recurse -Force
        Log-Message -Message "Previous script folders deleted." -Type "Success"
    }

    Log-Message -Message "Creating Temp Zoom path."
    New-Item -Path $TempZoomPath -ItemType Directory -Force | Out-Null
    Log-Message -Message "Temp Zoom path created successfully." -Type "Success"

    $zoomCheckResult = Check-ZoomInstalled
    if ($zoomCheckResult['Installed']) {
        if ($zoomCheckResult['Type'] -eq 'Regular' -and $zoomCheckResult['Version'] -ne "5.17.7") {
            Log-Message -Message "Regular Zoom version $($zoomCheckResult['Version']) is installed. Proceeding with update."
            Remove-OldZoom
            Download-AndInstallZoom
        } elseif ($zoomCheckResult['Type'] -eq 'MSI' -and $zoomCheckResult['Version'] -ne "5.17.31859") {
            Log-Message -Message "MSI Zoom version $($zoomCheckResult['Version']) is installed. Proceeding with update."
            Remove-OldZoom
            Download-AndInstallZoom
        } else {
            Log-Message -Message "Zoom is installed with the required version. No update needed." -Type "Success"
        }
    } else {
        Log-Message -Message "Zoom is not installed. Proceeding with installation."
        Download-AndInstallZoom
    }

    Remove-Item $TempZoomPath -Recurse -Force
    Log-Message -Message "Temporary files cleaned up." -Type "Success"
} catch {
    Log-Message -Message "An unexpected error occurred: $_" -Type "Error"
}

#Rechecking Zoom Version After Install
Check-ZoomInstalled
# Outputting Zoom installation details
Log-Message -Message "Zoom Installation Check Results:" -Type "Info"
Log-Message -Message "Installed: $($zoomCheckResult['Installed'])" -Type "Info"
Log-Message -Message "Version: $($zoomCheckResult['Version'])" -Type "Info"
Log-Message -Message "Type: $($zoomCheckResult['Type'])" -Type "Info"

exit
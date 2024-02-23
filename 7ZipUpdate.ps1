# This PowerShell script automates the process of downloading and installing the latest 64-bit version of 7-Zip. 
# It begins by constructing the download URL through a web request to the 7-Zip official website, 
# dynamically identifying the link for the latest x64 installer. 
# The script then downloads the installer to the system's temporary directory and initiates a silent installation with administrative privileges. 
# Finally, it cleans up by deleting the installer file post-installation, ensuring no residual files are left.

# - Constructing the download URL for the latest 64-bit version of 7-Zip. It does this by sending a web request to ‘https://7-zip.org/’, 
# - parsing the HTML to find the link that matches the criteria (it’s a download link, it starts with “a/”,
# - and it ends with “-x64.exe”), and then appending this link to the base URL (‘https://7-zip.org/’).
$dlurl = 'https://7-zip.org/' + (Invoke-WebRequest -UseBasicParsing -Uri 'https://7-zip.org/' | Select-Object -ExpandProperty Links | Where-Object {($_.outerHTML -match 'Download')-and ($_.href -like "a/*") -and ($_.href -like "*-x64.exe")} | Select-Object -First 1 | Select-Object -ExpandProperty href)



# - Creating the full path where the installer will be downloaded.
# - Using the system’s temporary directory as the base, and then appending the filename of the 7-Zip installer.
$installerPath = Join-Path $env:TEMP (Split-Path $dlurl -Leaf)



# - Downloading the 7-Zip installer from the URL constructed earlier
# - and saving it to the path constructed in the previous step.
Invoke-WebRequest $dlurl -OutFile $installerPath



# - Starting the 7-Zip installer with administrative privileges
# -  (“/S” is for silent installation and “-Verb RunAs” is for running as administrator). 
# - The “-Wait” argument means that the script will wait for the installer to finish before moving on to the next line.
Start-Process -FilePath $installerPath -Args "/S" -Verb RunAs -Wait



# - Deleting the installer file after the installation is complete.
Remove-Item $installerPath
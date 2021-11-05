# Set error action to continue, hide progress bar of webclient.downloadfile
$ErrorActionPreference = "Continue"
$ProgressPreference = 'SilentlyContinue'

# Install winget and enable local manifests since microsoft/winget-cli#1453 is merged
Invoke-WebRequest -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile 'VCLibs.appx'
Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile 'winget.msixbundle'
Invoke-WebRequest -Uri 'https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/9c0fe2ce7f8e410eb4a8f417de74517e_License1.xml' -OutFile 'license.xml'
Import-Module -Name Appx -UseWindowsPowerShell
Add-AppxProvisionedPackage -Online -PackagePath .\winget.msixbundle -DependencyPackagePath .\VCLibs.appx -LicensePath .\license.xml
# winget command on windows server -------------------
# Source: https://github.com/microsoft/winget-cli/issues/144#issuecomment-849108158
Install-Module NtObjectManager -Force # Install NtObjectManager module
$installationPath = (Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation # Create reparse point
Set-ExecutionAlias -Path "C:\Windows\System32\winget.exe" -PackageName "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" -EntryPoint "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget" -Target "$installationPath\AppInstallerCLI.exe" -AppType Desktop -Version 3
explorer.exe "shell:appsFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget"
# ----------------------------------------------------
winget settings --enable LocalManifestFiles
Write-Host " Successfully installed winget and enabled local manifests."

# Clone microsoft/winget-pkgs repository, copy YamlCreate.ps1 to the Tools folder, install dependencies, set settings for YamlCreate.ps1
git config --global user.name 'winget-pkgs-automation' # Set git username
git config --global user.email '83997633+vedantmgoyal2009@users.noreply.github.com' # Set git email
git clone https://vedantmgoyal2009:$env:GITHUB_TOKEN@github.com/microsoft/winget-pkgs.git --quiet # Clones the repository silently
$currentDir = Get-Location # Get current directory
Set-Location .\winget-pkgs\Tools # Change directory to Tools
git remote rename origin upstream # Rename origin to upstream
git remote add origin https://github.com/vedantmgoyal2009/winget-pkgs.git # Add fork to origin
Copy-Item -Path $currentDir\YamlCreate.ps1 -Destination .\YamlCreate.ps1 -Force # Copy YamlCreate.ps1 to Tools directory
git commit --all -m "Update YamlCreate.ps1 v2.0.0-unattended" # Commit changes
Set-Location $currentDir # Go back to previous working directory
Install-Module -Name powershell-yaml -Repository PSGallery -Scope CurrentUser -Force # Install powershell-yaml, required for YamlCreate.ps1
New-Item -ItemType File -Path "$env:LOCALAPPDATA\YamlCreate\Settings.yaml" -Force | Out-Null # Create Settings.yaml file
@"
TestManifestsInSandbox: always
SaveToTemporaryFolder: never
AutoSubmitPRs: always
ContinueWithExistingPRs: never
SuppressQuickUpdateWarning: true
EnableDeveloperOptions: true
"@ | Set-Content -Path $env:LOCALAPPDATA\YamlCreate\Settings.yaml # YamlCreate settings
Write-Host "Cloned repository, copied YamlCreate.ps1 to Tools directory, installed dependencies and set YamlCreate settings."

# Set up API headers
$header = @{
    Authorization = 'Basic {0}' -f $([System.Convert]::ToBase64String([char[]]"vedantmgoyal2009:$env:GITHUB_TOKEN"))
    Accept        = 'application/vnd.github.v3+json'
}

Function Update-PackageManifest ($PackageIdentifier, $PackageVersion, $InstallerUrls) {
    Write-Host -ForegroundColor Green "----------------------------------------------------"
    # Prints update information, added spaces for indentation
    Write-Host -ForegroundColor Green "[$Script:i/$Script:cnt] Found update for`: $PackageIdentifier"
    Write-Host -ForegroundColor Green "   Version`: $PackageVersion"
    Write-Host -ForegroundColor Green "   Download Urls`:"
    foreach ($i in $InstallerUrls) { Write-Host -ForegroundColor Green "      $i" }
    # Generate manifests and submit to winget community repository
    Write-Host -ForegroundColor Green "   Running YamlCreate.ps1 with the following configuration:" # Added spaces for indentation
    Set-Location .\winget-pkgs\Tools # Change directory to Tools
    if ($Script:package.yamlcreate_autoupgrade -eq $true -and $Script:package.check_existing_pr -eq $true) {
        Write-Host -ForegroundColor Green "      yamlcreate_autoupgrade: true`n      check_existing_pr: true" # Added spaces for indentation
        .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -AutoUpgrade
    }
    elseif ($Script:package.yamlcreate_autoupgrade -eq $false -and $Script:package.check_existing_pr -eq $false) {
        Write-Host -ForegroundColor Green "      yamlcreate_autoupgrade: false`n      check_existing_pr: false" # Added spaces for indentation
        .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls -SkipPRCheck
    }
    else {
        Write-Host -ForegroundColor Green "   Creating new manifest"
        .\YamlCreate.ps1 -PackageIdentifier $PackageIdentifier -PackageVersion $PackageVersion -Mode 2 -Param_InstallerUrls $InstallerUrls
    }
    Set-Location $currentDir # Go back to previous working directory
    Write-Host -ForegroundColor Green "----------------------------------------------------"
}

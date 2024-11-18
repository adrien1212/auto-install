# Configuration Variables
$destinationRoot = "C:\Program Files"
$tempDownloadPath = "$env:TEMP"
$sourceFolder = "E:\acaubel-local\Desktop\toinstall"  # Update with your actual source path

# Download URLs
$intelliJDownloadUrl = "https://download.jetbrains.com/idea/ideaIU-2024.1.exe"
$gitDownloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe"

# Installation Paths
$jdk17Path = "$destinationRoot\jdk-17"
$jdk21Path = "$destinationRoot\jdk-21"
$mavenPath = "$destinationRoot\maven-3.9.9"
$intelliJInstallerPath = "$sourceFolder\ideaIC-2024.3.exe"
$intelliJConfigFilePath = "$sourceFolder\idea-silent.config"
$intelliJInstallPath = "$destinationRoot\IntelliJ IDEA"


# Silent download
$ProgressPreference = 'SilentlyContinue'

# Function to download and install software
function Install-Software {
    param (
        [string]$Name,
        [string]$DownloadUrl,
        [string]$InstallerPath,
        [string[]]$InstallArgs = @(),
        [string]$DestinationPath = $null
    )

    Write-Host "Downloading $Name..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath

    Write-Host "Installing $Name..."
    if ($DestinationPath) {
        Start-Process -FilePath $InstallerPath -ArgumentList (@("/SILENT", "/DIR=$DestinationPath") + $InstallArgs) -Wait
    } else {
        Start-Process -FilePath $InstallerPath -ArgumentList (@("/SILENT") + $InstallArgs) -Wait
    }

    Write-Host "Cleaning up $Name installer..."
    Remove-Item $InstallerPath
}

# Function to copy folder
function Copy-Folder {
    param (
        [string]$SourceName,
        [string]$DestinationPath
    )
    $sourcePath = Join-Path -Path $sourceFolder -ChildPath $SourceName
    
    if (Test-Path $sourcePath) {
        Write-Host "Copying $SourceName to $DestinationPath..."
        Copy-Item -Path $sourcePath\* -Destination $DestinationPath -Recurse -Force
    } else {
        Write-Host "Source folder $SourceName not found. Skipping."
    }
}

# Ensure destination directories exist
@($jdk17Path, $jdk21Path, $mavenPath, $intelliJInstallPath) | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
    }
}

# Copy JDKs
Copy-Folder -SourceName "jdk-17" -DestinationPath $jdk17Path
Copy-Folder -SourceName "jdk-21" -DestinationPath $jdk21Path

# Copy Maven
Copy-Folder -SourceName "apache-maven-3.9.9" -DestinationPath $mavenPath

# Install Git (latest version)
Install-Software -Name "Git" -DownloadUrl $gitDownloadUrl -InstallerPath "$tempDownloadPath\git-installer.exe"

# Install IntelliJ
Start-Process -FilePath $intelliJInstallerPath -ArgumentList "/S /CONFIG=$intelliJConfigFilePath /D=$intelliJInstallPath" -Wait


# Set Environment Variables
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk17Path, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("M2_HOME", $mavenPath, [System.EnvironmentVariableTarget]::Machine)

# Update PATH
$binPaths = @(
    "$jdk17Path\bin",
    "$jdk21Path\bin",
    "$mavenPath\bin"
)

$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = $currentPath + ";" + ($binPaths -join ";")
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

Write-Host "Development environment setup completed successfully!"
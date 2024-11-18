# Configuration Variables
$destinationRoot = "C:\Program Files"
$tempDownloadPath = "$env:TEMP"

# Download URLs
$intelliJDownloadUrl = "https://download.jetbrains.com/idea/ideaIU-2024.1.exe"
$gitDownloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe"
$jdk17DownloadUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jdk_x64_windows_hotspot_17.0.13_11.zip"
$jdk21DownloadUrl = "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_x64_windows_hotspot_21.0.5_11.zip"
$mavenDownloadUrl = "https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip"

# Installation Paths
$jdk17Path = "$destinationRoot\jdk-17"
$jdk21Path = "$destinationRoot\jdk-21"
$mavenPath = "$destinationRoot\maven-3.9.9"
$intelliJInstallPath = "$destinationRoot\IntelliJ IDEA"

$intelliJConfigFilePath = "idea-silent.config"

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

# Function to download and extract zip
function Install-ZipSoftware {
    param (
        [string]$Name,
        [string]$DownloadUrl,
        [string]$DestinationPath
    )

    $zipPath = "$tempDownloadPath\$Name.zip"

    Write-Host "Downloading $Name..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipPath

    Write-Host "Extracting $Name..."
    Expand-Archive -Path $zipPath -DestinationPath $DestinationPath -Force

    Write-Host "Cleaning up $Name installer..."
    Remove-Item $zipPath
}

# Ensure destination directories exist
@($jdk17Path, $jdk21Path, $mavenPath, $intelliJInstallPath) | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
    }
}

# Install JDKs
Install-ZipSoftware -Name "jdk-17" -DownloadUrl $jdk17DownloadUrl -DestinationPath $jdk17Path
Install-ZipSoftware -Name "jdk-21" -DownloadUrl $jdk21DownloadUrl -DestinationPath $jdk21Path

# Install Maven
Install-ZipSoftware -Name "maven" -DownloadUrl $mavenDownloadUrl -DestinationPath $mavenPath

# Install Git
Install-Software -Name "Git" -DownloadUrl $gitDownloadUrl -InstallerPath "$tempDownloadPath\git-installer.exe"

# Install IntelliJ
Install-Software -Name "IntelliJ IDEA" `
    -DownloadUrl $intelliJDownloadUrl `
    -InstallerPath "$tempDownloadPath\intellij-installer.exe" `
    -DestinationPath $intelliJInstallPath `
    -InstallArgs @("/CONFIG=$intelliJConfigFilePath")

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

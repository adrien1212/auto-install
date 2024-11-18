# Configuration Variables
$destinationRoot = "C:\Program Files"
$tempDownloadPath = "$env:TEMP"

# Download URLs
$mariaDBDownloadUrl = "https://dlm.mariadb.com/3964460/MariaDB/mariadb-11.4.4/winx64-packages/mariadb-11.4.4-winx64.msi"
$heidiSQLDownloadUrl = "https://www.heidisql.com/downloads/releases/HeidiSQL_12.6_64_Portable.zip"

# Installation Paths
$mariaDBInstallPath = "$destinationRoot\MariaDB"
$heidiSQLInstallPath = "$destinationRoot\HeidiSQL"

# Silent install
$ProgressPreference = 'SilentlyContinue'

# Ensure destination directories exist
@($mariaDBInstallPath, $heidiSQLInstallPath) | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
    }
}

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

    if ($Name -eq "MariaDB") {
        Write-Host "Installing MariaDB..."
        Start-Process msiexec.exe -ArgumentList @("/i", $InstallerPath, "/qn", "INSTALLDIR=$DestinationPath") -Wait
    }
    elseif ($Name -eq "HeidiSQL") {
        Write-Host "Extracting HeidiSQL..."
        Expand-Archive -Path $InstallerPath -DestinationPath $DestinationPath -Force
    }

    Write-Host "Cleaning up $Name installer..."
    Remove-Item $InstallerPath
}

# Install MariaDB
Install-Software -Name "MariaDB" `
    -DownloadUrl $mariaDBDownloadUrl `
    -InstallerPath "$tempDownloadPath\mariadb-installer.msi" `
    -DestinationPath $mariaDBInstallPath

# Install HeidiSQL (Portable Version)
Install-Software -Name "HeidiSQL" `
    -DownloadUrl $heidiSQLDownloadUrl `
    -InstallerPath "$tempDownloadPath\heidisql-portable.zip" `
    -DestinationPath $heidiSQLInstallPath

# Update PATH
$binPaths = @(
    "$mariaDBInstallPath\bin"
)

$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = $currentPath + ";" + ($binPaths -join ";")
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# Set MariaDB Environment Variable
[System.Environment]::SetEnvironmentVariable("MARIADB_HOME", $mariaDBInstallPath, [System.EnvironmentVariableTarget]::Machine)

# Initial MariaDB Configuration
Write-Host "Configuring MariaDB..."
$mySqlInitCommands = @"
CREATE DATABASE IF NOT EXISTS test;
CREATE USER IF NOT EXISTS 'root'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"@

# PowerShell way to execute MySQL commands
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = "$mariaDBInstallPath\bin\mysql.exe"
$processInfo.RedirectStandardInput = $true
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true
$processInfo.Arguments = "-u root"

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo
$process.Start() | Out-Null

$process.StandardInput.WriteLine($mySqlInitCommands)
$process.StandardInput.Close()
$process.WaitForExit()

Write-Host "MariaDB and HeidiSQL installation completed successfully!"
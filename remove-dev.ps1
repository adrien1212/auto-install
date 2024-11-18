# Configuration Variables
$destinationRoot = "C:\Program Files"
$componentsToRemove = @(
    "jdk-17",
    "jdk-21",
    "maven-3.9.9",
    "IntelliJ IDEA"
)

# Function to remove directories
function Remove-Directory {
    param (
        [string]$Path
    )
    
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Recurse -Force
            Write-Host "Removed directory: $Path"
        }
        catch {
            Write-Host "Error removing directory: $Path - $_"
        }
    }
    else {
        Write-Host "Directory not found: $Path"
    }
}

# Function to remove environment variables
function Remove-EnvironmentVariable {
    param (
        [string]$VariableName
    )
    
    try {
        [System.Environment]::SetEnvironmentVariable($VariableName, $null, [System.EnvironmentVariableTarget]::Machine)
        Write-Host "Removed environment variable: $VariableName"
    }
    catch {
        Write-Host "Error removing environment variable: $VariableName - $_"
    }
}

# Function to remove PATH entries
function Remove-PathEntry {
    param (
        [string[]]$PathsToRemove
    )
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $newPath = ($currentPath -split ';' | Where-Object { 
            $path = $_
            -not ($PathsToRemove | Where-Object { $path -like "*$_*" })
        }) -join ';'
        
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Host "Updated PATH variable"
    }
    catch {
        Write-Host "Error updating PATH: $_"
    }
}

# Uninstall Git
try {
    $gitUninstaller = (Get-Item "C:\Program Files\Git\unins000.exe" -ErrorAction Stop)
    Start-Process $gitUninstaller.FullName -ArgumentList "/SILENT" -Wait
    Write-Host "Git uninstalled successfully"
}
catch {
    Write-Host "Git uninstaller not found or error during uninstallation"
}

# Remove directories
$componentsToRemove | ForEach-Object {
    Remove-Directory -Path (Join-Path $destinationRoot $_)
}

# Remove environment variables
@("JAVA_HOME", "M2_HOME") | ForEach-Object {
    Remove-EnvironmentVariable -VariableName $_
}

# Remove PATH entries
$pathEntriesToRemove = $componentsToRemove | ForEach-Object { "\$_\bin" }
Remove-PathEntry -PathsToRemove $pathEntriesToRemove

Write-Host "Development environment cleanup completed successfully!"

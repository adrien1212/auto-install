# Configuration Variables
$destinationRoot = "C:\Program Files"
$componentsToRemove = @(
    "MariaDB",
    "HeidiSQL"
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

# Uninstall MariaDB using MSI
try {
    $mariadbProduct = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*MariaDB*" }
    if ($mariadbProduct) {
        Start-Process msiexec.exe -ArgumentList "/x $($mariadbProduct.IdentifyingNumber) /qn" -Wait
        Write-Host "MariaDB uninstalled successfully"
    }
    else {
        Write-Host "MariaDB not found in installed programs"
    }
}
catch {
    Write-Host "Error uninstalling MariaDB: $_"
}

# Remove directories
$componentsToRemove | ForEach-Object {
    Remove-Directory -Path (Join-Path $destinationRoot $_)
}

# Remove environment variables
@("MARIADB_HOME") | ForEach-Object {
    Remove-EnvironmentVariable -VariableName $_
}

# Remove PATH entries
$pathEntriesToRemove = $componentsToRemove | ForEach-Object { "\$_\bin" }
Remove-PathEntry -PathsToRemove $pathEntriesToRemove

Write-Host "MariaDB and HeidiSQL removal completed successfully!"

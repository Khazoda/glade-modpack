Write-Host "Add Mod to Modpack" -ForegroundColor Cyan

# Prompt for platform
$platform = Read-Host "Platform (mr/cf)"
if ($platform -ne "mr" -and $platform -ne "cf") {
    Write-Host "Invalid platform. Use 'mr' or 'cf'" -ForegroundColor Red
    exit 1
}

# Prompt for mod ID
$modId = Read-Host "Mod ID or slug"
if ([string]::IsNullOrWhiteSpace($modId)) {
    Write-Host "Mod ID cannot be empty" -ForegroundColor Red
    exit 1
}

# Run packwiz command
$cmd = if ($platform -eq "mr") { "packwiz mr add $modId" } else { "packwiz cf add $modId" }
Write-Host "Running: $cmd" -ForegroundColor Yellow

$output = & cmd /c $cmd 2>&1 | Out-String
Write-Host $output

# Extract mod name from output (format: Project "Mod Name" successfully added!)
if ($output -match 'Project "([^"]+)" successfully added') {
    $modName = $matches[1]
    
    # Refresh index
    packwiz refresh | Out-Null
    
    # Update changelog
    & "$PSScriptRoot\Update-Changelog.ps1" -ModName $modName -Section "Added"
    
    Write-Host "`nMod added and changelog updated!" -ForegroundColor Green
} else {
    Write-Host "Failed to add mod or parse output" -ForegroundColor Red
    exit 1
}

Write-Host "Remove Mod from Modpack" -ForegroundColor Cyan

# Prompt for mod name/file
$modInput = Read-Host "Mod name or filename"
if ([string]::IsNullOrWhiteSpace($modInput)) {
    Write-Host "Mod name cannot be empty" -ForegroundColor Red
    exit 1
}

# Try to find the metafile to get proper name before removal
$modName = $modInput
$metaPath = "mods\$modInput.pw.toml"

if (Test-Path $metaPath) {
    $metaContent = Get-Content $metaPath -Raw
    if ($metaContent -match 'name = "([^"]+)"') {
        $modName = $matches[1]
    }
} else {
    # Try resourcepacks
    $metaPath = "resourcepacks\$modInput.pw.toml"
    if (Test-Path $metaPath) {
        $metaContent = Get-Content $metaPath -Raw
        if ($metaContent -match 'name = "([^"]+)"') {
            $modName = $matches[1]
        }
    }
}

# Remove the mod
Write-Host "Removing: $modInput" -ForegroundColor Yellow
$output = packwiz remove $modInput 2>&1 | Out-String
Write-Host $output

if ($LASTEXITCODE -eq 0) {
    # Refresh index
    packwiz refresh | Out-Null
    
    # Update changelog
    & "$PSScriptRoot\Update-Changelog.ps1" -ModName $modName -Section "Removed"
    
    Write-Host "`nMod removed and changelog updated!" -ForegroundColor Green
} else {
    Write-Host "Failed to remove mod" -ForegroundColor Red
    exit 1
}

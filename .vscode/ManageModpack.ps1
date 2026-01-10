function Show-Menu {
    $version = (Select-String -Path .\pack.toml -Pattern 'version\s*=\s*"([^"]+)"').Matches.Groups[1].Value
    
    Clear-Host
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "   Glade Modpack Manager" -ForegroundColor Cyan
    Write-Host "   Current Version: $version" -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Add Mod"
    Write-Host "2. Remove Mod"
    Write-Host "3. Set New Version"
    Write-Host "4. Prepare Release"
    Write-Host "5. Exit"
    Write-Host ""
}

function Add-Mod {
    Write-Host "`nAdd Mod" -ForegroundColor Cyan
    
    $platform = Read-Host "Platform (mr/cf)"
    if ($platform -ne "mr" -and $platform -ne "cf") {
        Write-Host "Invalid platform" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $modId = Read-Host "Mod ID or slug"
    if ([string]::IsNullOrWhiteSpace($modId)) {
        Write-Host "Mod ID cannot be empty" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $cmd = if ($platform -eq "mr") { "packwiz mr add $modId" } else { "packwiz cf add $modId" }
    $output = & cmd /c $cmd 2>&1 | Out-String
    Write-Host $output
    
    if ($output -match 'Project "([^"]+)" successfully added') {
        $modName = $matches[1]
        packwiz refresh | Out-Null
        & "$PSScriptRoot\Update-Changelog.ps1" -ModName $modName -Section "Added"
        Write-Host "`nMod added and changelog updated!" -ForegroundColor Green
    } else {
        Write-Host "Failed to add mod" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Remove-Mod {
    Write-Host "`nRemove Mod" -ForegroundColor Cyan
    
    $modInput = Read-Host "Mod name or filename"
    if ([string]::IsNullOrWhiteSpace($modInput)) {
        Write-Host "Mod name cannot be empty" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $modName = $modInput
    $metaPath = "mods\$modInput.pw.toml"
    
    if (Test-Path $metaPath) {
        $metaContent = Get-Content $metaPath -Raw
        if ($metaContent -match 'name = "([^"]+)"') {
            $modName = $matches[1]
        }
    } else {
        $metaPath = "resourcepacks\$modInput.pw.toml"
        if (Test-Path $metaPath) {
            $metaContent = Get-Content $metaPath -Raw
            if ($metaContent -match 'name = "([^"]+)"') {
                $modName = $matches[1]
            }
        }
    }
    
    $output = packwiz remove $modInput 2>&1 | Out-String
    Write-Host $output
    
    if ($LASTEXITCODE -eq 0) {
        packwiz refresh | Out-Null
        & "$PSScriptRoot\Update-Changelog.ps1" -ModName $modName -Section "Removed"
        Write-Host "`nMod removed and changelog updated!" -ForegroundColor Green
    } else {
        Write-Host "Failed to remove mod" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

function Set-Version {
    Write-Host "`nSet New Version" -ForegroundColor Cyan
    
    $currentVersion = (Select-String -Path .\pack.toml -Pattern 'version\s*=\s*"([^"]+)"').Matches.Groups[1].Value
    Write-Host "Current version: $currentVersion" -ForegroundColor Yellow
    
    $newVersion = Read-Host "New version"
    if ([string]::IsNullOrWhiteSpace($newVersion)) {
        Write-Host "Version cannot be empty" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    # Update pack.toml
    (Get-Content "pack.toml" -Raw) -replace 'version = "[^"]+"', "version = `"$newVersion`"" | Out-File "pack.toml" -Encoding utf8 -NoNewline
    
    # Create new changelog section
    $date = Get-Date -Format "yyyy-MM-dd"
    $newSection = @"
## [$newVersion] - $date

### Added
``````
``````

### Removed
``````
``````

### Updated
``````
``````

---

"@
    
    if (Test-Path "CHANGELOG.md") {
        $existingContent = Get-Content "CHANGELOG.md" -Raw
        if ($existingContent -match '# Changelog\s*\n') {
            $newContent = $existingContent -replace '(# Changelog\s*\n)', "`$1`n$newSection"
            $newContent | Out-File "CHANGELOG.md" -Encoding utf8 -NoNewline
        }
    }
    
    Write-Host "`nVersion updated to $newVersion and changelog section created!" -ForegroundColor Green
    Read-Host "`nPress Enter to continue"
}

function Prepare-Release {
    Write-Host "`nPrepare Release" -ForegroundColor Cyan
    
    $version = (Select-String -Path .\pack.toml -Pattern 'version\s*=\s*"([^"]+)"').Matches.Groups[1].Value
    Write-Host "Preparing release for version $version..." -ForegroundColor Yellow
    
    Write-Host "`nUpdating mods..."
    $updateOutput = packwiz update -a -y 2>&1 | Out-String
    Write-Host $updateOutput
    
    # Parse for updates
    $updateOutput -split "`n" | ForEach-Object {
        if ($_ -match '(.+?):\s+(.+?)\s+->\s+(.+)') {
            $modName = $matches[1].Trim()
            $oldFile = $matches[2].Trim()
            $newFile = $matches[3].Trim()
            
            $changeText = "$modName" + ": $oldFile -> $newFile"
            & "$PSScriptRoot\Update-Changelog.ps1" -ModName $changeText -Section "Updated"
        }
    }
    
    packwiz refresh
    
    $NAME = (Select-String -Path .\pack.toml -Pattern 'name\s*=\s*"([^"]+)"').Matches.Groups[1].Value -replace ' ', '-'
    $MC_VERSION = (Select-String -Path .\pack.toml -Pattern 'minecraft\s*=\s*"([^"]+)"').Matches.Groups[1].Value
    $OUTPUT_FILE = "${NAME}_${version}+${MC_VERSION}.mrpack"
    
    New-Item -ItemType Directory -Path "releases" -Force | Out-Null
    packwiz mr export -o "releases/$OUTPUT_FILE"
    
    if (Test-Path "releases/$OUTPUT_FILE") {
        $size = [math]::Round((Get-Item "releases/$OUTPUT_FILE").Length/1KB, 2)
        Write-Host "`nBuild complete: $OUTPUT_FILE ($size KB)" -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "  1. Review CHANGELOG.md"
        Write-Host "  2. git add ."
        Write-Host "  3. git commit -m 'Release v$version'"
        Write-Host "  4. git push"
        Write-Host "  5. Run GitHub Actions workflow"
    } else {
        Write-Host "`nBuild failed" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue"
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Select an option"
    
    switch ($choice) {
        "1" { Add-Mod }
        "2" { Remove-Mod }
        "3" { Set-Version }
        "4" { Prepare-Release }
        "5" { 
            Write-Host "`nExiting..." -ForegroundColor Green
            exit 
        }
        default { 
            Write-Host "`nInvalid choice" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

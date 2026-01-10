param([Parameter(Mandatory=$true)][string]$Version)

Write-Host "Preparing release $Version" -ForegroundColor Cyan

(Get-Content "pack.toml" -Raw) -replace 'version = "[^"]+"', "version = `"$Version`"" | Out-File "pack.toml" -Encoding utf8 -NoNewline

# Capture packwiz update output to detect changes
Write-Host "Updating mods..." -ForegroundColor Yellow
$updateOutput = packwiz update -a -y 2>&1 | Out-String
Write-Host $updateOutput

# Parse output for updated mods (format: "name: old.jar -> new.jar")
$updateOutput -split "`n" | ForEach-Object {
    if ($_ -match '(.+?):\s+(.+?)\s+->\s+(.+)') {
        $modName = $matches[1].Trim()
        $oldFile = $matches[2].Trim()
        $newFile = $matches[3].Trim()
        
        Write-Host "Detected update: $modName" -ForegroundColor Green
        $changeText = "$modName" + ": $oldFile -> $newFile"
        & "$PSScriptRoot\Update-Changelog.ps1" -ModName $changeText -Section "Updated"
    }
}

if ($LASTEXITCODE -ne 0) { exit 1 }

packwiz refresh
if ($LASTEXITCODE -ne 0) { exit 1 }

$NAME = (Select-String -Path .\pack.toml -Pattern 'name\s*=\s*"([^"]+)"').Matches.Groups[1].Value -replace ' ', '-'
$MC_VERSION = (Select-String -Path .\pack.toml -Pattern 'minecraft\s*=\s*"([^"]+)"').Matches.Groups[1].Value
$OUTPUT_FILE = "${NAME}_${Version}+${MC_VERSION}.mrpack"

New-Item -ItemType Directory -Path "releases" -Force | Out-Null
packwiz mr export -o "releases/$OUTPUT_FILE"

if (Test-Path "releases/$OUTPUT_FILE") {
    $size = [math]::Round((Get-Item "releases/$OUTPUT_FILE").Length/1KB, 2)
    Write-Host "Build complete: $OUTPUT_FILE ($size KB)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Changelog updated with mod changes"
    Write-Host "Next: Review CHANGELOG.md, then run:"
    Write-Host "  git add ."
    Write-Host "  git commit -m 'Release v$Version'"
    Write-Host "  git push"
} else {
    Write-Host "Build failed" -ForegroundColor Red
    exit 1
}

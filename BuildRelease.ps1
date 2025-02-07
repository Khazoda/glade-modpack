# Extract values from pack.toml
$NAME = (Select-String -Path .\pack.toml -Pattern 'name\s*=\s*"([^"]+)"').Matches.Groups[1].Value -replace ' ', '-'
$VERSION = (Select-String -Path .\pack.toml -Pattern 'version\s*=\s*"([^"]+)"').Matches.Groups[1].Value
$MC_VERSION = (Select-String -Path .\pack.toml -Pattern 'minecraft\s*=\s*"([^"]+)"').Matches.Groups[1].Value

# Error Handling
if (-Not $NAME -or -Not $VERSION -or -Not $MC_VERSION) {
  Write-Host "Error: Could not extract required fields from pack.toml!"
  exit 1
}

# Construct the output filename
$OUTPUT_FILE = "${NAME}_${VERSION}+${MC_VERSION}.mrpack"



# Export the modpack
New-Item -ItemType Directory -Path "releases" -Force
packwiz mr export -o "releases/$OUTPUT_FILE"

Write-Host "Modpack exported to: releases/$OUTPUT_FILE"
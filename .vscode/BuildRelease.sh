#!/bin/bash
# Extract values from pack.toml
NAME=$(grep -oP 'name\s*=\s*"\K[^"]+' pack.toml | tr ' ' '-')
VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' pack.toml)
MC_VERSION=$(grep -oP 'minecraft\s*=\s*"\K[^"]+' pack.toml)

# Error Handling
if [ -z "$NAME" ] || [ -z "$VERSION" ] || [ -z "$MC_VERSION" ]; then
  echo "Error: Could not extract required fields from pack.toml!"
  exit 1
fi

# Construct the output filename
OUTPUT_FILE="${NAME}_${VERSION}+${MC_VERSION}.mrpack"

# Export the modpack
mkdir -p releases
packwiz mr export -o "releases/$OUTPUT_FILE"

echo "Modpack exported to: releases/$OUTPUT_FILE"
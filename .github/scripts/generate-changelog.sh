#!/bin/bash
# Auto-generate changelog for current version from git diff
# This compares the current index.toml with the previous version to detect changes

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 2.0.11"
    exit 1
fi

echo "Generating changelog for version $VERSION..."

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Get the previous git tag
PREV_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")

if [ -z "$PREV_TAG" ]; then
    echo "No previous version found. Using initial commit."
    PREV_TAG=$(git rev-list --max-parents=0 HEAD)
fi

echo "Comparing with previous version: $PREV_TAG"

# Get old index.toml
git show "$PREV_TAG:index.toml" > "$TEMP_DIR/old_index.toml" 2>/dev/null || touch "$TEMP_DIR/old_index.toml"

# Extract mod information from index.toml files
extract_mods() {
    local file=$1
    grep -A 2 '^\[\[files\]\]' "$file" | \
    grep -E '^(file =|metafile =)' | \
    sed 's/file = "\(.*\)"/\1/' | \
    sed 's/metafile = "\(.*\)"/\1/' | \
    grep -v '^--$' || true
}

# Get mod lists
extract_mods "$TEMP_DIR/old_index.toml" | sort > "$TEMP_DIR/old_mods.txt"
extract_mods "index.toml" | sort > "$TEMP_DIR/new_mods.txt"

# Find differences
ADDED=$(comm -13 "$TEMP_DIR/old_mods.txt" "$TEMP_DIR/new_mods.txt")
REMOVED=$(comm -23 "$TEMP_DIR/old_mods.txt" "$TEMP_DIR/new_mods.txt")
COMMON=$(comm -12 "$TEMP_DIR/old_mods.txt" "$TEMP_DIR/new_mods.txt")

# Function to get mod name from path
get_mod_name() {
    basename "$1" | sed 's/\.pw\.toml$//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) tolower(substr($i,2))}}1'
}

# Check for updates in common mods by comparing file hashes
UPDATED=""
for mod in $COMMON; do
    if [ -f "$mod" ]; then
        OLD_HASH=$(git show "$PREV_TAG:$mod" 2>/dev/null | grep -oP 'hash = "\K[^"]+' | head -1 || echo "")
        NEW_HASH=$(grep -oP 'hash = "\K[^"]+' "$mod" | head -1 || echo "")
        
        if [ "$OLD_HASH" != "$NEW_HASH" ] && [ -n "$OLD_HASH" ] && [ -n "$NEW_HASH" ]; then
            UPDATED="$UPDATED$mod"$'\n'
        fi
    fi
done

# Generate changelog
OUTPUT="## [$VERSION] - $(date +%Y-%m-%d)

"

# Add custom notes placeholder if this is interactive
if [ -t 0 ]; then
    OUTPUT="$OUTPUT### Notes
<!-- Add any custom notes here -->

"
fi

# Updated mods
if [ -n "$UPDATED" ]; then
    OUTPUT="$OUTPUT### Updated
\`\`\`
"
    echo "$UPDATED" | while read -r mod; do
        if [ -n "$mod" ]; then
            NAME=$(get_mod_name "$mod")
            OUTPUT="$OUTPUT- $NAME
"
        fi
    done
    OUTPUT="$OUTPUT\`\`\`

"
fi

# Added mods
if [ -n "$ADDED" ]; then
    OUTPUT="$OUTPUT### Added
\`\`\`
"
    echo "$ADDED" | while read -r mod; do
        if [ -n "$mod" ]; then
            NAME=$(get_mod_name "$mod")
            OUTPUT="$OUTPUT- $NAME
"
        fi
    done
    OUTPUT="$OUTPUT\`\`\`

"
fi

# Removed mods
if [ -n "$REMOVED" ]; then
    OUTPUT="$OUTPUT### Removed
\`\`\`
"
    echo "$REMOVED" | while read -r mod; do
        if [ -n "$mod" ]; then
            NAME=$(get_mod_name "$mod")
            OUTPUT="$OUTPUT- $NAME
"
        fi
    done
    OUTPUT="$OUTPUT\`\`\`

"
fi

OUTPUT="$OUTPUT---
"

# Output or prepend to CHANGELOG.md
if [ "$2" == "--output" ]; then
    echo "$OUTPUT"
else
    # Prepend to CHANGELOG.md
    if [ -f "CHANGELOG.md" ]; then
        TEMP_CHANGELOG=$(mktemp)
        echo "# Changelog

All notable changes to the Glade modpack will be documented in this file.

$OUTPUT" > "$TEMP_CHANGELOG"
        tail -n +4 CHANGELOG.md >> "$TEMP_CHANGELOG"
        mv "$TEMP_CHANGELOG" CHANGELOG.md
        echo "✓ Prepended changelog to CHANGELOG.md"
    else
        echo "$OUTPUT" > CHANGELOG.md
        echo "✓ Created CHANGELOG.md"
    fi
fi

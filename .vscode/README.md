# Local Scripts

##PrepareRelease.ps1

Prepares a release:
- Updates `pack.toml` version
- Runs `packwiz update -a -y`
- Auto-detects and logs updated mods to CHANGELOG.md

```powershell
.\PrepareRelease.ps1 -Version "2.0.12"
```

## AddMod.ps1

Adds a mod and updates CHANGELOG.md:

```powershell
.\AddMod.ps1
```

Prompts for platform (modrinth/curseforge) and mod ID.

## RemoveMod.ps1

Removes a mod and updates CHANGELOG.md:

```powershell
.\RemoveMod.ps1
```

Prompts for mod name to remove.

## BuildRelease.ps1

Builds .mrpack with current pack.toml version:

```powershell
.\BuildRelease.ps1
```

## Update-Changelog.ps1

Helper function used by other scripts to append mod names to CHANGELOG.md sections.

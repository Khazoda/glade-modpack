# Local Scripts

## PrepareRelease.ps1

Prepares a complete release before pushing:

```powershell
.\PrepareRelease.ps1 -Version "2.0.12"
```

Updates version, refreshes mods, generates changelog, and tests build.

## BuildRelease.ps1

Builds .mrpack with current version in pack.toml:

```powershell
.\BuildRelease.ps1
```

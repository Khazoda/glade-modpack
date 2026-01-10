## How to Publish a Release

1. **Update `pack.toml`** - Bump the `version` field up

2. **Update `CHANGELOG.md`** - Add release notes at the top

3. **Click the "Build & Publish Modpack" button:**
   - Go to **Actions** tab
   - Click **"Build & Publish Modpack"**
   - Click **"Run workflow"** → **"Run workflow"**

The workflow will:
- ✅ Build the `.mrpack` file
- ✅ Create a GitHub release with the provided changelog
- ✅ Publish to Modrinth
- ✅ Feature the new version and unfeature old ones
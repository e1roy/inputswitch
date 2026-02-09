Build the project as a DMG and create a GitHub release.

Version: $ARGUMENTS

Steps:
1. Run `./build-dmg.sh` to build the universal binary DMG
2. Verify the DMG file exists in the `dist/` directory
3. Use `gh release create` to create a new GitHub release with the specified version tag and upload the DMG file
4. The version tag should have a `v` prefix (e.g., `v0.0.3`)
5. Generate release notes from recent git commits since the last tag
6. Print the release URL when done

# Run the exercise

1. From the repository root, open the project:

   ```sh
   open lab.ios.Pinning.xcodeproj
   ```

2. In Xcode, select the `lab.ios.Pinning` scheme.
3. Select an installed iPhone Simulator running iOS 17 or newer.
4. Run the app with `⌘R`.
5. Run the included tests with `⌘U`.

The checked-in hosted configuration carries the hosted leaf pin applied on
2026-09-29. Certificate renewal changes that value, so refresh it from the
material below after a rotation. Do not create or select `Config/Local.xcconfig`
unless the trainer instructs you to use a local server.

## Refreshing the hosted certificate material

The hosted server rotates its certificate on renewal, so the leaf pin in
`Config/Hosted.xcconfig` must track it. The current material is published as a
zip:

1. Download `https://zsk.labs.def.dev/pinning/material.zip`.
2. Open `pinning.xcconfig` inside the zip.
3. Copy its `LAB_URL_SLASH` and `LAB_LEAF_PIN` lines over the matching lines in
   `Config/Hosted.xcconfig`.
4. Rebuild with `⌘R` and run the tests with `⌘U`; the Restore state should
   connect again.

No other file changes. A future tool will apply the bundle automatically; until
then the steps above are deliberately manual.

## Switching branches

The project uses Xcode buildable folders, so the checked-in project file is the
same on every branch and lists folders rather than sources: switching branches
changes the files on disk without changing anything Xcode watches. A session
that stays open across a switch can keep building against the branch you left
and fail with errors about files or types that are not in the current branch.

Clean before rebuilding after a branch switch:

Product → Clean Build Folder (⇧⌘K)

Closing and reopening the project re-enumerates the folders as well. If the
stale error survives both, delete the project's DerivedData folder and rebuild.

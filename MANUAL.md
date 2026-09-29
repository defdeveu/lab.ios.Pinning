# Run the exercise

1. From the repository root, open the project:

   ```sh
   open lab.ios.Pinning.xcodeproj
   ```

2. In Xcode, select the `lab.ios.Pinning` scheme.
3. Select an installed iPhone Simulator running iOS 17 or newer.
4. Run the app with `⌘R`.
5. Run the included tests with `⌘U`.

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

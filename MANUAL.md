# Run the exercise

1. From the repository root, open the project:

   ```sh
   open lab.ios.Pinning.xcodeproj
   ```

2. In Xcode, select the `lab.ios.Pinning` scheme.
3. Select an installed iPhone Simulator running iOS 17 or newer.
4. Run the app with `⌘R`.
5. Run the included tests with `⌘U`.

The checked-in configuration pins the hosted issuing CA set in `Info.plist`
under `NSAppTransportSecurity`. Placeholder digests ship until the hosted
certificate exists; this branch has no local-server mode.

## Refreshing the hosted certificate material

The hosted server rotates its certificate on renewal, and the pinned CA set
must follow the authority it presents. The current material is published as a
zip:

1. Download `https://zsk.labs.def.dev/pinning/material.zip`.
2. Open `pinned-ca-identities.plist` inside the zip.
3. In `lab.ios.Pinning/Info.plist`, update the `NSPinnedCAIdentities` digests:
   the fragment carries the presented issuer (normally the first entry); keep
   the second entry as the backup pin and replace it when the trainer
   distributes a backup value.
4. Rebuild with `⌘R`; Connect should succeed again.

No other file changes. A future tool will apply the bundle automatically; until
then the steps above are deliberately manual.

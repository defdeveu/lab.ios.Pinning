# Run the exercise

1. From the repository root, open the project:

   ```sh
   open lab.ios.Pinning.xcodeproj
   ```

2. In Xcode, select the `lab.ios.Pinning` scheme.
3. Select an installed iPhone Simulator running iOS 17 or newer.
4. Run the app with `⌘R`.
5. Run the included tests with `⌘U`.

The checked-in hosted configuration is ready to use once the hosted leaf pin is
in place: `LAB_LEAF_PIN` ships as a placeholder until the first hosted
certificate exists. Do not create or select `Config/Local.xcconfig` unless the
trainer instructs you to use a local server.

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

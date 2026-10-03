# iOS Pinning lab

Open `lab.ios.Pinning.xcodeproj` with Xcode 27 or newer. The project targets iOS 17 and uses Swift 6.

The trainer will provide the exercise instructions, server environment, and expected outcomes. The hosted endpoint comes from `Config/Hosted.xcconfig`; the pinned issuing CA set is committed in `Info.plist` under `NSAppTransportSecurity`.

This branch targets the HTTP/3-only route: the app requests HTTP/3 for every connection, the server refuses a request that fell back to TCP with `505 HTTP Version Not Supported`, and the app shows the protocol it negotiated. The Simulator is sufficient.

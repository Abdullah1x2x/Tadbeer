# iOS home-screen widget (setup in Xcode)

The widget's code is in `TadbeerWidget.swift`. The Dart side
(`lib/features/widgets/home_widget_sync.dart`) already writes its data to the
app group `group.com.tadbeer.app`. Adding the widget target needs Xcode on a
Mac (it has not been built or tested yet):

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension.** Name it `TadbeerWidget`,
   untick *Include Configuration App Intent* and *Include Live Activity*.
   Deployment target: iOS 14 or later.
3. Delete the Swift file Xcode generates in the new `TadbeerWidget` group and
   add the existing `ios/TadbeerWidget/TadbeerWidget.swift` to the
   `TadbeerWidget` target instead.
4. For **both** the `Runner` and `TadbeerWidget` targets: *Signing &
   Capabilities → + Capability → App Groups*, and add
   `group.com.tadbeer.app`.
5. In the `Runner` target, under *Build Phases*, make sure
   *Embed Foundation Extensions* contains `TadbeerWidget.appex`, and move it
   above *Run Script* if Xcode reports a build cycle.
6. Build and run on a device, then long-press the home screen → **+** →
   **تَدْبِير**.

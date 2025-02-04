import SwiftUI
import Application

@main
struct TheHopfinityGauntletApp: App {
#if os(macOS)
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  init() {}

  var body: some Scene {
    WindowGroup {
      if horizontalSizeClass == .compact {
        MainView()
      } else {
        MainView()
          .frame(minWidth: 300, minHeight: 300)
      }
    }
  }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Return true to quit the app when the last window is closed.
    return true
  }
}
#endif

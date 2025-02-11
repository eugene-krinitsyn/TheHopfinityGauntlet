import SwiftUI
import Application

@main
struct TheHopfinityGauntletApp: App {
#if os(macOS)
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif

  init() {}

  var body: some Scene {
    WindowGroup {
#if os(macOS)
      MainView()
        .frame(minWidth: 300, minHeight: 300)
#else
      MainView()
#endif
    }
  }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidBecomeActive(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Return true to quit the app when the last window is closed.
    return true
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
    if !hasVisibleWindows {
      for window in sender.windows {
        window.makeKeyAndOrderFront(nil)
      }
    }
    // Also ensure the app is active:
    NSApp.activate(ignoringOtherApps: true)
    return true
  }
}
#endif

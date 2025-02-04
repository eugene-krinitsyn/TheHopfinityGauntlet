import Foundation
import SwiftUI

public struct MainView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  let presetsStore = BRPresetsStore()

#if os(iOS)
  @State private var router = Router()
#endif

  public init() {}

  public var body: some View {
#if os(iOS)
    NavigationStack(path: $router.routes) {
      BRPresetsView(store: presetsStore)
        .navigationDestination(for: Route.self) { route in
          router.destination(for: route)
        }
    }
    .environment(\.navigate, NavigateAction(action: { route in
      Task { @MainActor in
        router.routes.append(route)
      }
    }))
#else
    SplitView(store: SplitStore(presetsStore: presetsStore))
#endif
  }
}

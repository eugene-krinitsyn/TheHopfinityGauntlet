import Foundation
import SwiftUI

public struct MainView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  //let presetsStore = BRPresetsStore()
  let splitStore = SplitStore(presetsStore: BRPresetsStore())
  @StateObject var cartStore = BRCartStore()

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
    SplitView(store: splitStore)
      .environmentObject(cartStore)
#endif
  }
}

#Preview {
  MainView()
}

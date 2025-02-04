import Foundation
import SwiftUI

#if os(iOS)
@Observable @MainActor
final class Router: Sendable {
  var routes: [Route] = []

  @ViewBuilder
  func destination(for route: Route) -> some View {
    switch route {
    case .results(let results):
      BRResultsView(store: BRResultsStore(beers: results))
    }
  }
}
#endif

enum Route: Hashable, Sendable {
  case results([BeerRepublicItem])
}

struct NavigateAction: Sendable {
  typealias Action = @Sendable (Route) -> ()
  let action: Action?

  func callAsFunction(_ route: Route) {
    action?(route)
  }
}

struct NavigateEnvironmentKey: EnvironmentKey {
  static let defaultValue = NavigateAction(action: nil)
}

extension EnvironmentValues {
  var navigate: (NavigateAction) {
    get { self[NavigateEnvironmentKey.self] }
    set { self[NavigateEnvironmentKey.self] = newValue }
  }
}

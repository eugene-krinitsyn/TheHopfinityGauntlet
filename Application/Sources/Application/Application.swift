import Foundation
import SwiftUI

public struct MainView: View {
  let brMainStore = BRMainStore()

  public init() {}

  public var body: some View {
    BRMainView(store: brMainStore)
  }
}

import Foundation
import SwiftUI

extension View {
  @ViewBuilder
  func menuIndicatorHidden() -> some View {
    if #available(macOS 12.0, *) {
      menuIndicator(.hidden)
    } else {
      self
    }
  }
}

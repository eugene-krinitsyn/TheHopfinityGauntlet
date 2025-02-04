import Foundation
import SwiftUI

struct SplitView: View {
  @ObservedObject var store: SplitStore

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      BRPresetsView(store: store.presetsStore)
        .frame(maxWidth: 340)
      Color.black
        .frame(width: 1)
      if let resultsStore = store.resultsStore {
        BRResultsView(store: resultsStore)
      } else {
        Spacer(minLength: 300)
      }
    }
  }
}

#Preview {
  SplitView(store: .init(presetsStore: BRPresetsStore()))
}

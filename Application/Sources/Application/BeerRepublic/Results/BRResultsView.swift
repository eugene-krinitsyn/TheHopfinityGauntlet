import Foundation
import SwiftUI
import BeerRepublicAPI
import Kingfisher

struct BRResultsView: View {
  @ObservedObject var store: BRResultsStore
  @Environment(\.openURL) private var openURL
  @EnvironmentObject private var cart: BRCartStore

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Text("Found \(store.beers.count) beers")
        Spacer()
      }

      BRBeerListView(beers: $store.beers)

      if !store.beers.isEmpty {
        Button("Add all to cart") {
          withAnimation {
            cart.beers.appendUnique(contentsOf: store.beers)
            store.beers = []
          }
        }
      }
    }
    .padding(16)
  }
}

#Preview {
  BRResultsView(store: .init(beers: .previewBulk()))
}

#Preview {
  BRResultsView(store: .init(beers: []))
}

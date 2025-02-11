import Foundation
import SwiftUI
import BeerRepublicAPI
import Kingfisher

struct BRResultsView: View {
  @ObservedObject var store: BRResultsStore
  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Text("Found ^[\(store.beers.count) beer](inflect: true)")
        Spacer()
      }

      buildBeersResultsView(store.beers)

      if !store.beers.isEmpty {
        Button("Add all to cart") {
          Task { @MainActor in
            if let url = await store.getCartLink() {
              openURL(url)
            }
          }
        }
      }
    }
    .padding(16)
  }
}

private extension BRResultsView {
  @ViewBuilder
  func buildBeersResultsView(_ beers: [BeerRepublicItem]) -> some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(beers) { beer in
          buildItemView(beer)
        }
      }
    }
  }

  @ViewBuilder
  func buildItemView(_ item: BeerRepublicItem) -> some View {
    HStack(spacing: 0) {
      HStack(alignment: .top, spacing: 10) {
        KFImage(item.image)
          .placeholder {
            Color.gray.opacity(0.1)
          }
          .resizable()
          .retry(maxCount: 3)
          .aspectRatio(contentMode: .fit)
          .frame(width: 60, height: 100)

        VStack(alignment: .leading, spacing: 4) {
          HStack(alignment: .top, spacing: 10) {
            Text(item.vendor + " - " + item.title)
              .font(.headline)
              .multilineTextAlignment(.leading)

            Spacer()

            Button {
              withAnimation {
                store.onTapRemoveBeer(item)
              }
            } label: {
              Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
          }

          Text(item.style)
            .foregroundColor(.secondary)

          if let date = store.getBeerExpiration(item) {
            Text("Expires on: \(date)")
              .foregroundColor(.secondary)
          }

          if let price = store.getBeerPrice(item) {
            Text(price)
              .bold()
          }

          HStack {
            Button {
              Task { @MainActor in
                if let url = store.getBeerLink(item) {
                  openURL(url)
                }
              }
            } label: {
              Text("Beer Republic")
            }

            Button {
              Task { @MainActor in
                if let url = store.getUntappdSearchLink(item) {
                  openURL(url)
                }
              }
            } label: {
              Text("Untappd")
            }
          }
        }
      }

      Spacer()
    }
    .padding(16)
    .background(Color.black.opacity(0.1))
    .cornerRadius(8)
  }
}

#Preview {
  BRResultsView(store: .init(beers: .previewBulk()))
}

#Preview {
  BRResultsView(store: .init(beers: []))
}

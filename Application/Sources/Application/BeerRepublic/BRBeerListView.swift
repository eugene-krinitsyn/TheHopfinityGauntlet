import Foundation
import SwiftUI
import Kingfisher

struct BRBeerListView: View {
  @Binding var beers: [BeerRepublicItem]

  @Environment(\.openURL) private var openURL

  var body: some View {
    buildBeersResultsView(beers)
  }
}

private extension BRBeerListView {
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
                guard let index = beers.firstIndex(where: { $0.id == item.id }) else {
                  return
                }
                beers.remove(at: index)
              }
            } label: {
              Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
          }

          Text(item.style)
            .foregroundColor(.secondary)

          if let date = getBeerExpiration(item) {
            Text("Expires on: \(date)")
              .foregroundColor(.secondary)
          }

          if let price = getBeerPrice(item) {
            Text(price)
              .bold()
          }

          HStack {
            Button {
              openURL(getBeerLink(item))
            } label: {
              Text("Beer Republic")
            }

            Button {
              openURL(getUntappdSearchLink(item))
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

private extension BRBeerListView {
  private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd-MM-yyyy"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
  }()

  private static let numberFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.numberStyle = .currency
    f.maximumFractionDigits = 2
    return f
  }()

  func getBeerLink(_ beer: BeerRepublicItem) -> URL! {
    URL(string: "https://beerrepublic.eu" + beer.url)
  }

  func getUntappdSearchLink(_ beer: BeerRepublicItem) -> URL! {
    URL(string: "https://untappd.com/search?q=\(beer.vendor) \(beer.title)")
  }

  func getBeerPrice(_ beer: BeerRepublicItem) -> String? {
    Self.numberFormatter.currencyCode = beer.currencyCode
    return Self.numberFormatter.string(from: NSNumber(floatLiteral: Double(beer.price)))
  }

  func getBeerExpiration(_ beer: BeerRepublicItem) -> String? {
    guard let expirationDate = beer.expirationDate else { return nil }
    return Self.dateFormatter.string(from: expirationDate)
  }
}

@available(iOS 17, macOS 14, *)
#Preview {
  @Previewable @State var beers = BeerRepublicItem.previewBulk()
  BRBeerListView(beers: $beers)
}

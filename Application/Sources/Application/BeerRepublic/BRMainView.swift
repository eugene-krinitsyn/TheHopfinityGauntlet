import Foundation
import SwiftUI
import BeerRepublicAPI

struct BRMainView: View {
  @Environment(\.openURL) var openURL
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  @ObservedObject var store: BRMainStore

  var body: some View {
    VStack(alignment: .center, spacing: 10) {
      Text("Beer Republic")

      if let filters = store.filters {
        VStack(alignment: horizontalSizeClass == .compact ? .leading : .center, spacing: 20) {
          if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 20) {
              buildFiltersList(filters)
            }
            VStack(alignment: .leading, spacing: 20) {
              buildPreferencesInputs()
            }
          } else {
            HStack(alignment: .top, spacing: 10) {
              buildFiltersList(filters)
            }
            HStack(alignment: .center, spacing: 10) {
              buildPreferencesInputs()
            }
          }
          buildScanButton()
          if let beers = store.beers {
            buildScanResultsView(beers)
          } else if let error = store.error {
            buildErrorMessageView(error)
          }
          Spacer()
        }
        .padding(16)
      } else {
        VStack {
          Spacer()
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
          Spacer()
        }
      }
    }
  }
}

// MARK: - View Builders

private extension BRMainView {
  @ViewBuilder
  func buildFiltersList(_ filters: [String: [String]]) -> some View {
    ForEach(filters.map { $0.key }.sorted(), id: \.self) { key in
      if let values = filters[key] {
        VStack(alignment: .leading, spacing: 10) {
          buildMenu(values, key: key)

          if let selected = store.preferences.selectedFilters[key] {
            buildSelectedFiltersList(selected, for: key)
          }
        }
      }
    }
  }

  @ViewBuilder
  func buildMenu(_ values: [String], key: String) -> some View {
    Menu {
      ForEach(values.sorted(), id: \.self) { value in
        Button {
          store.preferences.selectFilter(value, type: key)
        } label: {
          if store.preferences.selectedFilters[key]?.contains(value) == true {
            Label(value, systemImage: "checkmark")
          } else {
            Text(value)
          }
        }
      }
    } label: {
      Text(key)
    }
  }

  @ViewBuilder
  func buildSelectedFiltersList(_ selectedFilters: [String], for key: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      ForEach(selectedFilters, id: \.self) { value in
        HStack(alignment: .center, spacing: 8) {
          Button {
            store.preferences.selectFilter(value, type: key)
          } label: {
            Image(systemName: "xmark.circle")
          }
          Text(value)
        }
      }
    }
  }

  @ViewBuilder
  func buildPreferencesInputs() -> some View {
    buildUsernameTextField()
    buildPriceLimitTextField()
    buildOrderLimitTextField()
    buildQuantityLimitTextField()
    buildExpirationDatePicker()
  }

  @ViewBuilder
  func buildUsernameTextField() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Untappd username:")
      TextField("", text: $store.preferences.untappdUsername)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
    }
  }

  @ViewBuilder
  func buildPriceLimitTextField() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Max beer price:")
      TextField("", text: $store.preferences.priceLimit)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
    }
  }

  @ViewBuilder
  func buildOrderLimitTextField() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Max order price:")
      TextField("", text: $store.preferences.orderLimit)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
    }
  }

  @ViewBuilder
  func buildQuantityLimitTextField() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Max amount:")
      TextField("", text: $store.preferences.quantityLimit)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
    }
  }

  @ViewBuilder
  func buildExpirationDatePicker() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Expires later than:")
      DatePicker(selection: $store.preferences.expirationDate, in: Date()..., displayedComponents: [.date]) {
        EmptyView()
      }
      .labelsHidden()
    }
  }

  @ViewBuilder
  func buildErrorMessageView(_ error: Error) -> some View {
    Text(error.localizedDescription)
      .multilineTextAlignment(.leading)
      .foregroundColor(.red)
  }

  @ViewBuilder
  func buildScanButton() -> some View {
    HStack {
      Button("Scan beers") {
        store.onTapScan()
      }
      .disabled(store.isScanning)
      if store.isScanning {
        ProgressView()
      }
    }
  }

  @ViewBuilder
  func buildScanResultsView(_ beers: [BeerRepublicItem]) -> some View {
    Text("Found \(beers.count) beers matching the filters")
    if !beers.isEmpty {
      Button("Open BeerRepublic and add to cart") {
        Task { @MainActor in
          if let url = await store.getCardLink() {
            openURL(url)
          }
        }
      }

      buildBeersResultsView(beers)
    }
  }

  @ViewBuilder
  func buildBeersResultsView(_ beers: [BeerRepublicItem]) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        ForEach(beers) { beer in
          HStack(alignment: .center, spacing: 10) {
            Button {
              store.onTapRemoveBeer(beer)
            } label: {
              Image(systemName: "xmark.circle")
            }

            VStack(alignment: .leading, spacing: 0) {
              Text(beer.product.product.vendor)
                .lineLimit(1)
              Text(beer.product.product.title)
                .lineLimit(1)
              if let date = store.getBeerExpiration(beer) {
                Text(date)
              }
              if let price = store.getBeerPrice(beer) {
                Text(price)
              }

              Button {
                Task { @MainActor in
                  if let url = store.getBeerLink(beer) {
                    openURL(url)
                  }
                }
              } label: {
                Text("Open")
              }
            }
          }
        }
      }
    }
  }
}

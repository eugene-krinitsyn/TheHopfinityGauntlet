import Foundation
import SwiftUI
import BeerRepublicAPI
import Kingfisher

struct BRPresetsView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.navigate) private var navigate

  @ObservedObject var store: BRPresetsStore

  @State private(set) var isScanning: Bool = false
  @State private(set) var error: Error?

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let filters = store.filters {
        ScrollView {
          VStack(alignment: .leading, spacing: 40) {
            KFImage(URL(string: "https://cdn.shopify.com/s/files/1/0691/2887/files/Beer_Republic_Logo_BLUE_Tekengebied_1_91245b1c-e467-4cf4-b428-2a558d37aa7b.png")!)
              .resizable()
              .retry(maxCount: 3)
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: 150)

            VStack(alignment: .leading, spacing: 20) {
              Text("Filters")
                .font(.headline)
              buildFiltersList(filters)
            }

            VStack(alignment: .leading, spacing: 20) {
              Text("Limits")
                .font(.headline)
              buildPriceLimitTextField()
              buildOrderLimitTextField()
              buildQuantityLimitTextField()
              buildExpirationDatePicker()
            }

            VStack(alignment: .leading, spacing: 20) {
              Text("Personalization")
                .font(.headline)
              buildUsernameTextField()
            }

            if let error {
              buildErrorMessageView(error)
            }

            buildScanButton()
              .padding(.top, error == nil ? 50 : 0)

            Spacer()
          }
          .padding(16)
        }
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

private extension BRPresetsView {
  @ViewBuilder
  func buildFiltersList(_ filters: [String: [String]]) -> some View {
    VStack(alignment: .leading, spacing: 20) {
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
  }

  @ViewBuilder
  func buildMenu(_ values: [String], key: String) -> some View {
    HStack(alignment: .center, spacing: 8) {
      let isFilterActive: Bool = store.preferences.selectedFilters.contains(where: { $0.key == key })
      Text(key.capitalized)
        .foregroundColor(isFilterActive ? Color(.textActive) : Color(.textInactive))

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
        Image(systemName: "plus.circle.fill")
      }
      .menuStyle(.borderlessButton)
      .buttonStyle(.plain)
      .labelsHidden()
      .menuIndicatorHidden()
      .frame(width: 20, height: 20)
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
          .buttonStyle(.plain)
          Text(value)
        }
      }
    }
  }

  @ViewBuilder
  func buildUsernameTextField() -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("Scan with Untappd username:")
        .foregroundColor(store.preferences.getUsername() == nil ? Color(.textInactive) : Color(.textActive))
      TextField("", text: $store.preferences.untappdUsername)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
    }
  }

  @ViewBuilder
  func buildPriceLimitTextField() -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("Limit price per beer:")
        .foregroundColor(store.preferences.getPriceLimit() == nil ? Color(.textInactive) : Color(.textActive))
      TextField("", text: $store.preferences.priceLimit)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
    }
  }

  @ViewBuilder
  func buildOrderLimitTextField() -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("Limit order price:")
        .foregroundColor(store.preferences.getOrderLimit() == nil ? Color(.textInactive) : Color(.textActive))
      TextField("", text: $store.preferences.orderLimit)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
    }
  }

  @ViewBuilder
  func buildQuantityLimitTextField() -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("Limit amount:")
        .foregroundColor(store.preferences.getQuantityLimit() == nil ? Color(.textInactive) : Color(.textActive))
      TextField("", text: $store.preferences.quantityLimit)
        .textFieldStyle(.roundedBorder)
        .disableAutocorrection(true)
    }
  }

  @ViewBuilder
  func buildExpirationDatePicker() -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("Assure expiration is later than:")
        .foregroundColor(store.preferences.getExpirationDate() == nil ? Color(.textInactive) : Color(.textActive))
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
      Button {
        isScanning = true
        Task { @MainActor in
          do {
            let beers = try await store.scanForBeers()
            navigate(.results(beers))
          } catch {
            self.error = error
          }
          isScanning = false
        }
      } label: {
        HStack {
          Spacer()
          Text("Scan beers")
          if isScanning {
            ProgressView()
              .controlSize(.small)
          }
          Spacer()
        }
        .padding(.vertical, 10)
        .foregroundColor(Color.white)
        .background(Color.blue)
        .cornerRadius(8)
        .contentShape(.rect)
      }
      .disabled(isScanning)
      .buttonStyle(.plain)
    }
  }
}

#Preview {
  BRPresetsView(store: BRPresetsStore())
}

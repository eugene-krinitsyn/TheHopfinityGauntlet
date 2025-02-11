import Foundation
import SwiftUI
import BeerRepublicAPI
import Kingfisher

struct BRPresetsView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.navigate) private var navigate

  @ObservedObject var store: BRPresetsStore
  @State private var error: Error?

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
  func buildFiltersList(_ filters: [BRFilter]) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      ForEach(filters) { filter in
        VStack(alignment: .leading, spacing: 10) {
          buildMenu(filter)

          if let selected = store.preferences.selectedFilters[filter.key] {
            buildSelectedFiltersList(selected, for: filter.key)
          }
        }
      }
    }
  }

  @ViewBuilder
  func buildMenu(_ filter: BRFilter) -> some View {
    let isFilterActive: Bool = store.preferences.selectedFilters.contains(where: { $0.key == filter.key })

    FilterView(
      filter: filter,
      isFilterActive: isFilterActive,
      isFilterValueSelected: { value in
        store.preferences.selectedFilters.contains(where: { $0.value.contains(value) })
      },
      selectFilterKeyValue: { key, value in
        store.preferences.selectFilter(value, type: key)
      }
    )
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
        if store.scanningTask != nil {
          store.scanningTask?.cancel()
          store.scanningTask = nil
        } else {
          store.scanningTask = Task { @MainActor in
            do {
              let beers = try await store.scanForBeers()
              navigate(.results(beers))
            } catch {
              self.error = error
            }
            store.scanningTask = nil
          }
        }
      } label: {
        HStack {
          Spacer()
          Text(store.scanningTask != nil ? "Cancel" : "Scan beers")
          if store.scanningTask != nil {
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
      .buttonStyle(.plain)
    }
  }
}

// MARK: - Filter View

struct FilterView: View {
  let filter: BRFilter
  let isFilterActive: Bool
  let isFilterValueSelected: (String) -> Bool
  let selectFilterKeyValue: (String, String) -> Void
  @State private var showPopover = false

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      Text(filter.key.capitalized)
        .foregroundColor(isFilterActive ? Color(.textActive) : Color(.textInactive))

      Button {
        showPopover = true
      } label: {
        Image(systemName: "plus.circle.fill")
      }
      .popover(isPresented: $showPopover) {
        PopoverMenu(
          filter: filter,
          isFilterValueSelected: isFilterValueSelected,
          selectFilterKeyValue: selectFilterKeyValue
        )
      }


//      Menu {
//        ForEach(values.sorted(), id: \.self) { value in
//          Button {
//            store.preferences.selectFilter(value, type: key)
//          } label: {
//            if store.preferences.selectedFilters[key]?.contains(value) == true {
//              Label(value, systemImage: "checkmark")
//            } else {
//              Text(value)
//            }
//          }
//        }
//      } label: {
//        Image(systemName: "plus.circle.fill")
//      }
//      .menuStyle(.borderlessButton)
//      .buttonStyle(.plain)
//      .labelsHidden()
//      .menuIndicatorHidden()
//      .frame(width: 20, height: 20)
    }
  }
}


// MARK: - Popover Menu

struct PopoverMenu: View {
  let filter: BRFilter
  let isFilterValueSelected: (String) -> Bool
  let selectFilterKeyValue: (String, String) -> Void
  @Environment(\.presentationMode) @Binding
  private var presentationMode

  var body: some View {
    VStack(alignment: .leading) {
      Text("Select \(filter.key.capitalized)")
        .font(.headline)
        .padding(.horizontal)
      Divider()
      ScrollView {
        VStack(alignment: .leading) {
          ForEach(filter.values, id: \.self) { value in
            HStack {
              Toggle(
                isOn: Binding(
                  get: { isFilterValueSelected(value) },
                  set: { _ in
                    selectFilterKeyValue(filter.key, value)
                  }
                )
              ) {
                HStack {
                  Text(value)
                  Spacer()
                }
              }
            }
          }
        }
        .padding(.horizontal)
      }
      Divider()
      Button("Done") {
        presentationMode.dismiss()
      }
      .padding(.horizontal)
    }
    .padding(.vertical)
    .frame(maxHeight: 500)
  }
}

#Preview {
  BRPresetsView(store: BRPresetsStore())
}

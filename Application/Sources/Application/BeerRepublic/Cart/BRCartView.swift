import SwiftUI

struct BRCartView: View {
  @EnvironmentObject var store: BRCartStore
  @Environment(\.openURL) private var openURL

  @Environment(\.presentationMode) @Binding
  private var presentationMode

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Text("\(store.beers.count) beers")
      }

      if !store.beers.isEmpty {
        Divider()

        BRBeerListView(beers: $store.beers)
          .frame(maxWidth: 350, minHeight: 400, maxHeight: 700)

        Divider()

        HStack(alignment: .center, spacing: 0) {
          Button("Open cart in Beer Republic") {
            Task { @MainActor in
              if let url = await store.getCartLink() {
                openURL(url)
              }
            }
          }

          Spacer()

          Button("Clean cart") {
            store.beers = []
          }
        }
      }
    }
    .padding(16)
  }
}

@available(iOS 17, macOS 14, *)
#Preview {
  @Previewable @ObservedObject var store: BRCartStore = {
    let store = BRCartStore()
    store.beers = .previewBulk()
    return store
  }()

  BRCartView()
    .environmentObject(store)
}

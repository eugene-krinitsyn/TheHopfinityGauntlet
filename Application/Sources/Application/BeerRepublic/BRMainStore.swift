import Foundation

@MainActor
final class BRMainStore: ObservableObject, Sendable {

  @Published private(set) var filters: [String: [String]]?
  @Published var preferences = BRPreferences()
  @Published private(set) var isScanning: Bool = false
  @Published private(set) var error: Error?
  @Published private(set) var beers: [BeerRepublicItem]?

  private var repository = BeerRepublicRepository()

  private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd-MM-yyyy"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
  }()

  private let numberFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.numberStyle = .currency
    f.maximumFractionDigits = 2
    return f
  }()

  init() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        filters = try await repository.getFilters()
      } catch {
        self.error = error
      }
    }
  }
}

// MARK: - User interactions

extension BRMainStore {
  func onTapScan() {
    beers = nil
    preferences.save()
    isScanning = true

    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        beers = try await repository.getBeers(
          filters: preferences.selectedFilters,
          untappdUsername: preferences.getUsername(),
          priceLimit: preferences.getPriceLimit(),
          orderLimit: preferences.getOrderLimit(),
          quantityLimit: preferences.getQuantityLimit(),
          expirationDateLimit: preferences.getExpirationDate()
        )
      } catch {
        self.error = error
      }
      isScanning = false
    }
  }

  func getCardLink() async -> URL? {
    guard let beers else { return nil }
    return await repository.getCartLink(for: beers)
  }

  func getBeerLink(_ beer: BeerRepublicItem) -> URL? {
    URL(string: "https://beerrepublic.eu" + beer.product.product.url)
  }

  func getBeerPrice(_ beer: BeerRepublicItem) -> String? {
    numberFormatter.currencyCode = beer.product.price.currencyCode
    return numberFormatter.string(from: NSNumber(floatLiteral: Double(beer.product.price.amount)))
  }

  func getBeerExpiration(_ beer: BeerRepublicItem) -> String? {
    guard let expirationDate = beer.expirationDate else { return nil }
    return dateFormatter.string(from: expirationDate)
  }

  func onTapRemoveBeer(_ beer: BeerRepublicItem) {
    guard let index = beers?.firstIndex(where: { $0.product.id == beer.product.id }) else {
      return
    }
    beers?.remove(at: index)
  }
}

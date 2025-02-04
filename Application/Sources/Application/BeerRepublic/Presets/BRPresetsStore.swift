import Foundation

@MainActor
final class BRPresetsStore: ObservableObject, Sendable {

  @Published private(set) var filters: [String: [String]]?
  @Published var preferences = BRPreferences()

  @Published private(set) var searchResults: [BeerRepublicItem]?

  private var repository = BeerRepublicRepository()

  init() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        filters = try await repository.getFilters()
      } catch {
        print(error.localizedDescription)
      }
    }
  }
}

// MARK: - User interactions

extension BRPresetsStore {
  func scanForBeers() async throws -> [BeerRepublicItem] {
    preferences.save()

    let beers = try await repository.getBeers(
      filters: preferences.selectedFilters,
      untappdUsername: preferences.getUsername(),
      priceLimit: preferences.getPriceLimit(),
      orderLimit: preferences.getOrderLimit(),
      quantityLimit: preferences.getQuantityLimit(),
      expirationDateLimit: preferences.getExpirationDate()
    )
    searchResults = beers
    return beers
  }
}

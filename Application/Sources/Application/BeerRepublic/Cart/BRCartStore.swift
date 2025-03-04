import Foundation

@MainActor
final class BRCartStore: ObservableObject {
  @Published var beers: [BeerRepublicItem] = []
  private var repository = BeerRepublicRepository()

  func getCartLink() async -> URL? {
    return await repository.getCartLink(for: beers)
  }
}

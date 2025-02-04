import Foundation

@MainActor
final class BRResultsStore: ObservableObject, Sendable {
  @Published private(set) var beers: [BeerRepublicItem]
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

  init(beers: [BeerRepublicItem]) {
    self.beers = beers
  }

  func getCartLink() async -> URL? {
    return await repository.getCartLink(for: beers)
  }

  func getBeerLink(_ beer: BeerRepublicItem) -> URL? {
    URL(string: "https://beerrepublic.eu" + beer.url)
  }

  func getUntappdSearchLink(_ beer: BeerRepublicItem) -> URL? {
    URL(string: "https://untappd.com/search?q=\(beer.vendor) \(beer.title)")
  }

  func getBeerPrice(_ beer: BeerRepublicItem) -> String? {
    numberFormatter.currencyCode = beer.currencyCode
    return numberFormatter.string(from: NSNumber(floatLiteral: Double(beer.price)))
  }

  func getBeerExpiration(_ beer: BeerRepublicItem) -> String? {
    guard let expirationDate = beer.expirationDate else { return nil }
    return dateFormatter.string(from: expirationDate)
  }

  func onTapRemoveBeer(_ beer: BeerRepublicItem) {
    guard let index = beers.firstIndex(where: { $0.id == beer.id }) else {
      return
    }
    beers.remove(at: index)
  }
}

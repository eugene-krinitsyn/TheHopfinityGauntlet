import Foundation

@MainActor
final class BRResultsStore: ObservableObject, Sendable {
  @Published var beers: [BeerRepublicItem]
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
}

import Foundation
import BeerRepublicAPI
import UntappdAPI

struct BeerRepublicItem: Identifiable, Hashable {
  let id: String
  let beerId: String
  let title: String
  let vendor: String
  let url: String
  let price: Float
  let currencyCode: String
  let expirationDate: Date?
}

extension BeerRepublicItem {
  init(product: ProductModel, expirationDate: Date?) {
    self.init(
      id: product.id,
      beerId: product.product.id,
      title: product.product.title,
      vendor: product.product.vendor,
      url: product.product.url,
      price: product.price.amount,
      currencyCode: product.price.currencyCode,
      expirationDate: expirationDate
    )
  }
}

extension BeerRepublicItem {
  static func preview() -> BeerRepublicItem {
    BeerRepublicItem(
      id: Mock.id(),
      beerId: Mock.id(),
      title: Mock.name(),
      vendor: Mock.name(),
      url: "www.google.com",
      price: Float((5...100).randomElement() ?? 0),
      currencyCode: "EUR",
      expirationDate: Mock.date(of: [.future], isNearest: .random())
    )
  }

  static func previewBulk(size: Int = 20) -> [BeerRepublicItem] {
    (1...size).map { _ in .preview() }
  }
}

extension Array where Element == BeerRepublicItem {
  static func previewBulk(size: Int = 20) -> [BeerRepublicItem] {
    BeerRepublicItem.previewBulk(size: size)
  }
}

import Foundation
import BeerRepublicAPI
import UntappdAPI

struct BeerRepublicItem: Identifiable {
  var id: String {
    product.id
  }

  let product: ProductModel
  let expirationDate: Date?
}

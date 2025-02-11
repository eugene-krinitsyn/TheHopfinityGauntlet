import Foundation
import SwiftSoup
import NetworkSession

public struct CollectionModel: Decodable, Sendable {

  public let products: [ProductModel]
  public let lastPage: Int?

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let htmlString = try container.decode(String.self)
    let doc: Document = try SwiftSoup.parse(htmlString)
    let metaJSON = try doc.getCollectionJSON()

    if let data = metaJSON.data(using: .utf8) {
      do {
        let decodedMeta = try JSONDecoder().decode(CollectionContainer.self, from: data)
        products = decodedMeta.products
      } catch {
        throw NetworkError.undefined(message: "Failed to decode meta JSON: \(error.localizedDescription)")
      }
    } else {
      throw NetworkError.undefined(message: "Couldn't parse HTML")
    }

    lastPage = try? doc.getLastPage()
  }
}

struct CollectionContainer: Decodable, Sendable {
  let products: [ProductModel]

  private enum CodingKeys: String, CodingKey {
    case collection
    case productVariants
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder
      .container(keyedBy: CodingKeys.self)
      .nestedContainer(keyedBy: CodingKeys.self, forKey: .collection)
    products = try container.decode([ProductModel].self, forKey: .productVariants)
  }
}

public struct ProductModel: Decodable, Sendable {
  public let price: PriceModel
  public let product: ProductItemModel
  public let id: String
  public let sku: String
  public let title: String
  public let untranslatedTitle: String
  public let image: ImageModel?
}

public struct PriceModel: Decodable, Sendable {
  public let amount: Float
  public let currencyCode: String
}

public struct ProductItemModel: Decodable, Sendable {
  public let title: String
  public let vendor: String
  public let id: String
  public let untranslatedTitle: String
  public let url: String // "\/products\/double-bag?_pos=3\u0026_fid=738a0eb3b\u0026_ss=c"
  public let type: String //  "Brown \u0026 Dark"
}

public struct ImageModel: Decodable, Sendable {
  public let src: String // "\/\/beerrepublic.eu\/cdn\/shop\/files\/DoubleBag_1.png?v=1734145690"
}

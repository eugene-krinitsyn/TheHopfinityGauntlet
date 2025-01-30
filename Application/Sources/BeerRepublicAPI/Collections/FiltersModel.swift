import Foundation
import SwiftSoup

public struct FiltersModel: Decodable, Sendable {

  public let filters: [String: [String]]

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let htmlString = try container.decode(String.self)
    let doc: Document = try SwiftSoup.parse(htmlString)
    filters = try doc.getFilters()
  }
}

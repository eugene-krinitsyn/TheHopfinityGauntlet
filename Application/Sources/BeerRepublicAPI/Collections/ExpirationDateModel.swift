import Foundation
import SwiftSoup

public struct ExpirationDateModel: Decodable, Sendable {
  public let date: Date

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let htmlString = try container.decode(String.self)
    let doc: Document = try SwiftSoup.parse(htmlString)
    date = try doc.getExpirationDate()
  }
}

import Foundation
import SwiftSoup
import NetworkSession

public struct CheckinSearchResultsModel: Decodable, Sendable {

  public let results: [CheckinSearchResultModel]

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let htmlString = try container.decode(String.self)
    let doc: Document = try SwiftSoup.parse(htmlString)

    // Select all beer-item elements:
    // .distinct-list-list (the container) -> .beer-item (the actual items)
    let beerElements = try doc.select("div.distinct-list-list div.beer-item")

    var results: [CheckinSearchResultModel] = []

    for element in beerElements {
      // 1) data-bid attribute
      let dataBid = try element.attr("data-bid")

      // 2) Beer name: text inside the anchor with data-href=":view/name"
      //
      // For example: <p class="name"><a data-href=":view/name">Mexican Sotol Barrel-Aged Pentuple</a></p>
      //
      // We'll select that anchor. Then use `.text()` to get the displayed name.
      let nameAnchor = try element.select("p.name a[data-href=':view/name']").first()
      let beerName = try nameAnchor?.text() ?? ""

      let item = CheckinSearchResultModel(bid: dataBid, name: beerName)
      results.append(item)
    }

    self.results = results
  }
}

public struct CheckinSearchResultModel: Sendable {
  public let bid: String
  public let name: String
}

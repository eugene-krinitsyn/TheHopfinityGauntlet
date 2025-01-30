import Foundation
import NetworkSession

public struct OrdersModel: Decodable, Sendable {

  public let pageInfo: PageInfoModel
  public let itemIDs: [String]

  private enum CodingKeys: String, CodingKey {
    case data, customer, orders, nodes, pageInfo, reorderPath
  }

  public init(from decoder: any Decoder) throws {
    let ordersContainer = try decoder
      .container(keyedBy: CodingKeys.self)
      .nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
      .nestedContainer(keyedBy: CodingKeys.self, forKey: .customer)
      .nestedContainer(keyedBy: CodingKeys.self, forKey: .orders)
    pageInfo = try ordersContainer.decode(PageInfoModel.self, forKey: .pageInfo)
    let nodes = try ordersContainer.decode([NodeModel].self, forKey: .nodes)
    itemIDs = nodes.flatMap { $0.itemIDs }
  }
}

public struct PageInfoModel: Decodable, Sendable {
  public let hasNextPage: Bool
  public let hasPreviousPage: Bool
  public let startCursor: String
  public let endCursor: String
}

private struct NodeModel: Decodable, Sendable {
  let itemIDs: [String]

  enum CodingKeys: CodingKey {
    case reorderPath
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let reorderPath: String = try container.decode(String.self, forKey: .reorderPath)
    let url = URL(string: "https://sample.com" + reorderPath)!
    if let lastPath = url.pathComponents.last {
      let itemIDs: [String] = lastPath
        .components(separatedBy: ",")
        .compactMap { $0.components(separatedBy: ":").first }
      self.itemIDs = itemIDs
    } else {
      throw NetworkError.undefined(message: "Couldn't parse reorder path")
    }
  }
}

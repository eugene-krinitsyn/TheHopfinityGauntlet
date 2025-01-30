import Foundation

public enum ResponseType: Sendable {
  case localCache, httpCache, regular
}

public struct NetworkResponse<Model: Decodable & Sendable>: Sendable {
  public let result: Model
  public let type: ResponseType
  public let headers: [String: String]
  public let statusCode: Int
}

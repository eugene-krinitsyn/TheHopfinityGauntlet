import Foundation

public struct CodeRequestModel: Decodable, Sendable {
  public let email: String
  public let uuid: String
  public let token: String
  public let analytics_trace_id: String?
}

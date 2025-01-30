import Foundation

public struct AuthCompleteModel: Decodable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case redirectURL = "redirect_url"
    case token = "token"
    case verificationType = "verification_type"
    case email = "email"
  }

  public let redirectURL: URL
  public let token: String
  public let verificationType: String
  public let email: String
}

import Foundation

public struct Token: Decodable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case expiresIn = "expires_in"
  }

  public let accessToken: String
  public let expiresIn: Int
}

import Foundation
import NetworkSession

struct ClientKeys: Sendable {

  let shopID: String
  let clientId: String
  let locale: String
  let nonce: String
  let redirectUri: String
  let responseType: String
  let scope: String
  let state: String
  let redirectURL: URL

  init(with locationURL: URL, shopID: String) throws {
    self.shopID = shopID
    redirectURL = locationURL
    guard let components = URLComponents(url: locationURL, resolvingAgainstBaseURL: true),
    let queryItems = components.queryItems else {
      throw NetworkError.undefined(message: "Couldn't break location URL into components")
    }
    let query = queryItems.reduce(into: [String: String]()) { (result, item) in
      result[item.name] = item.value
    }

    guard let clientId = query["client_id"] else {
      throw NetworkError.undefined(message: "Missing client id")
    }
    self.clientId = clientId

    guard let locale = query["locale"] else {
      throw NetworkError.undefined(message: "Missing locale")
    }
    self.locale = locale
    
    guard let nonce = query["nonce"] else {
      throw NetworkError.undefined(message: "Missing nonce")
    }
    self.nonce = nonce

    guard let redirectUri = query["redirect_uri"] else {
      throw NetworkError.undefined(message: "Missing redirect uri")
    }
    self.redirectUri = redirectUri

    guard let responseType = query["response_type"] else {
      throw NetworkError.undefined(message: "Missing response type")
    }
    self.responseType = responseType
    
    guard let scope = query["scope"] else {
      throw NetworkError.undefined(message: "Missing scope")
    }
    self.scope = scope

    guard let state = query["state"] else {
      throw NetworkError.undefined(message: "Missing state")
    }
    self.state = state
  }
}

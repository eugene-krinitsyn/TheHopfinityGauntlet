import Foundation
import SwiftSoup
import NetworkSession

struct AuthBasicsModel: Decodable, Sendable {

  let state: String
  let codeChallenge: String
  let codeChallengeMethod: String
  let scope: String
  let responseMode: String
  let responseType: String
  let redirectUri: String

  init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let htmlString = try container.decode(String.self)
    let doc: Document = try SwiftSoup.parse(htmlString)

    guard let element = try doc.select("shop-login-button").first() else {
      throw NetworkError.undefined(message: "Couldn't find auth basics")
    }

    codeChallenge = try element.attr("code-challenge")
    codeChallengeMethod = try element.attr("code-challenge-method")
    redirectUri = try element.attr("redirect-uri")
    responseMode = try element.attr("response-mode")
    responseType = try element.attr("response-type")
    scope = try element.attr("scope")
    state = try element.attr("state")
  }
}

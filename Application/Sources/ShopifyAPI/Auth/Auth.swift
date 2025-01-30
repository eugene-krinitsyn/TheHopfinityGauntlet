import Foundation
import NetworkSession

extension ShopifyAPI {
  actor Auth {
    var configuration: ShopifyAPI.Configuration

    private(set) var token: Token?
    private var refreshTask: Task<Token, Error>?

    private(set) var clientKeys: ClientKeys?
    private(set) var authBasics: AuthBasicsModel?
    private(set) var codeResponse: CodeRequestModel?

    init(configuration: ShopifyAPI.Configuration) {
      self.configuration = configuration

      if let token = Self.restoreToken() {
        self.token = token
      }

      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        self.token = Token(accessToken: "", expiresIn: 0)
      }
    }
  }
}

// MARK: - Authorisation

extension ShopifyAPI.Auth {
  func authorize(for email: String) async throws -> CodeRequestModel {
    let keysResponse = try await perform(requestClientKeys())
    guard let locationHeader = keysResponse.headers["Location"],
          let locationURL = URL(string: locationHeader),
          let shopID = keysResponse.headers["x-shopid"] else {
      throw NetworkError.undefined(message: "Could not extract location from headers")
    }
    let clientKeys = try ClientKeys(with: locationURL, shopID: shopID)
    self.clientKeys = clientKeys
    try await perform(prewarmAuth(with: clientKeys))
    authBasics = try await perform(requestAuthBasics(with: clientKeys)).result
    let request = requestCodeForEmail(email)
    let codeResponse = try await perform(request).result
    self.codeResponse = codeResponse
    return codeResponse
  }

  func confirmAuthorization(for codeRequest: CodeRequestModel, with code: String) async throws {
    guard let authBasics, let clientKeys, let codeResponse else {
      throw NetworkError.undefined(message: "Auth basics or client keys are missing")
    }
    let confirmationRequest = requestAuthConfirmation(for: codeRequest, with: code)
    let confirmationResponse = try await perform(confirmationRequest)
    let postAuthStep1Request = requestPostAuthStep1(
      with: confirmationResponse.result,
      codeRequest: codeResponse,
      basics: authBasics,
      keys: clientKeys
    )
    _ = try await configuration.networkSession.urlSession.data(for: postAuthStep1Request)
    let tokenRequest = requestAccessToken()
    let tokenResponse = try await perform(tokenRequest)
    token = tokenResponse.result
    Self.saveToken(tokenResponse.result)
  }

  func invalidateAuthorization() {
    token = nil
    Self.saveToken(nil)
  }
}

// MARK: - Token storage

private extension ShopifyAPI.Auth {
  static func saveToken(_ token: Token?) {
    UserDefaults.standard.set(token?.accessToken, forKey: "accessToken")
    UserDefaults.standard.set(token?.expiresIn, forKey: "expiresIn")
  }

  static func restoreToken() -> Token? {
    guard let accessToken = UserDefaults.standard.string(forKey: "accessToken"),
          let expiresIn = UserDefaults.standard.value(forKey: "expiresIn") as? Int
    else {
      return nil
    }
    print("=== TOKEN: \(accessToken) ===")
    return Token(accessToken: accessToken, expiresIn: expiresIn)
  }

  static func restoreLegacyToken() -> String? {
    UserDefaults.standard.string(forKey: "accessToken")
  }
}

// MARK: Request execution

private extension ShopifyAPI.Auth {
  @discardableResult
  func perform<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    try await configuration.networkSession.perform(request)
  }
}

// MARK: Requests

extension ShopifyAPI.Auth {
  func requestClientKeys() -> NetworkRequest<EmptyModel> {
    let url = configuration.basePath
    return NetworkRequest(URLString: url)
      .setHeaders([
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      ])
      .setPreventRedirects(true)
  }

  func prewarmAuth(with keys: ClientKeys) -> NetworkRequest<EmptyModel> {
    let url = "https://shopify.com/authentication/\(keys.shopID)/oauth/authorize"
    return NetworkRequest(URLString: url)
      .setParameters(.query([
        "client_id": keys.clientId,
        "nonce": keys.nonce,
        "redirect_uri": keys.redirectUri,
        "response_type": keys.responseType,
        "scope": keys.scope,
        "state": keys.state
      ]))
  }

  func requestAuthBasics(with keys: ClientKeys) -> NetworkRequest<AuthBasicsModel> {
    let url = "https://shopify.com/authentication/\(keys.shopID)/login"
    return NetworkRequest(URLString: url)
      .setParameters(.query([
        "client_id": keys.clientId,
        "locale": keys.locale,
        "redirect_uri": keys.redirectURL.absoluteString
      ]))
  }

  func requestCodeForEmail(_ email: String) -> NetworkRequest<CodeRequestModel> {
    let url = configuration.authBasePath + "/pay/authentication/login/start"
    return NetworkRequest(URLString: url)
      .setMethod(.POST)
      .setParameters(.json([
        "origin": "login_with_shop",
        "email": email,
        "passkeys_supported": true,
        "fast_login": false,
        "shopify_domain": configuration.shopifyDomain,
        "verification_type": "email",
        "authorization_flow": "default",
        "authentication_level": "email",
        "flow": "self_serve_customer_accounts",
      ]))
  }

  func requestAuthConfirmation(for codeRequest: CodeRequestModel, with code: String) -> NetworkRequest<AuthCompleteModel> {
    let url = configuration.authBasePath + "/pay/authentication/login/complete"
    return NetworkRequest(URLString: url)
      .setMethod(.POST)
      .setParameters(.json([
        "origin": "login_with_shop",
        "passkeys_supported": true,
        "shopify_domain": configuration.shopifyDomain,
        "verification_type": "email",
        "authorization_flow": "default",
        "authentication_level": "email",
        "flow": "self_serve_customer_accounts",
        "client_uuid": codeRequest.uuid,
        "verification_token": codeRequest.token,
        "code": code
      ]))
  }

  func requestPostAuthStep1(
    with authComplete: AuthCompleteModel,
    codeRequest: CodeRequestModel,
    basics: AuthBasicsModel,
    keys: ClientKeys
  ) -> URLRequest {
    let url = "https://shop.app/pay/sdk-trampoline"
    let parameters = [
      "response_type": basics.responseType,
      "response_mode": basics.responseMode,
      "client_id": keys.clientId,
      "shop_permanent_domain": configuration.shopifyDomain,
      "scope": basics.scope,
      "redirect_type": "top_frame",
      "redirect_uri": basics.redirectUri,
      "state": basics.state,
      "flow": "default",
      "flow_version": "unspecified",
      "code_challenge": basics.codeChallenge,
      "code_challenge_method": basics.codeChallengeMethod,
      "target_origin": "https://shopify.com",
      "first_name": "undefined",
      "last_name": "undefined",
      "sign_in_method": "unified_login_component",
      "session_token": authComplete.token,
//      "analytics_trace_id": codeRequest.analytics_trace_id,
//      "analytics_context": "self_serve_customer_accounts"
    ]

    let query = parameters.map { key, value in
      "\(key.customURLEncoded())=\(value.customURLEncoded())"
    }.joined(separator: "&")

    var urlRequest = URLRequest(url: URL(string: url + "?" + query)!)
    urlRequest.setValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
    urlRequest.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
    urlRequest.setValue("cross-site", forHTTPHeaderField: "Sec-Fetch-Site")
    urlRequest.setValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")

    let allowedDomains: [String] = [configuration.basePath, configuration.authBasePath]
      .compactMap { URL(string: $0) }
      .compactMap { $0.host }
    let allCookies = HTTPCookieStorage.shared.cookies ?? []
    let combinedCookieHeader: String = allCookies
      .filter { cookie in
        allowedDomains.contains(where: { $0.contains(cookie.domain) })
      }
      .map { "\($0.name)=\($0.value)" }
    .joined(separator: "; ")
    urlRequest.setValue(combinedCookieHeader, forHTTPHeaderField: "Cookie")
    return urlRequest
  }

//  func requestPostAuthStep2() -> NetworkRequest<EmptyModel> {
//    let url = "https://shopify.com/authentication/6912887/login/external/shop/callback"
//    return NetworkRequest(URLString: url)
//      .setParameters(.query([
//        ...
//      ]))
//  }

  func requestAccessToken() -> NetworkRequest<Token> {
    let url = configuration.basePath + "/oauth/token"
    return NetworkRequest(URLString: url)
  }
}

private extension String {
  func customURLEncoded() -> String {
    let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~ ")
    let encoded = self.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? self
    return encoded.replacingOccurrences(of: " ", with: "+")
  }
}

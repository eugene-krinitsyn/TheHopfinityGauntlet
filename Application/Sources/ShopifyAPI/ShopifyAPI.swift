import Foundation
import NetworkSession

public final class ShopifyAPI: Sendable {
  let configuration: Configuration

  let auth: Auth
  public let customer: Customer

  public init(configuration: Configuration) {
    self.configuration = configuration
    self.auth = Auth(configuration: configuration)
    self.customer = Customer(configuration: configuration)
  }
}

public extension ShopifyAPI {
  struct Configuration: Sendable {
    public let networkSession: NetworkSession
    public let basePath: String
    let authBasePath: String
    public let shopifyDomain: String
    public let authEmailProvider: @Sendable () async throws -> String
    public let confirmationCodeProvider: @Sendable () async throws -> String

    public init(
      networkSession: NetworkSession,
      basePath: String,
      shopifyDomain: String,
      authEmailProvider: @escaping @Sendable () async throws -> String,
      confirmationCodeProvider: @escaping @Sendable () async throws -> String
    ) {
      self.networkSession = networkSession
      self.basePath = basePath
      self.shopifyDomain = shopifyDomain
      authBasePath = "https://pay.shopify.com"
      self.authEmailProvider = authEmailProvider
      self.confirmationCodeProvider = confirmationCodeProvider
    }
  }
}

public protocol Configurable {
  var configuration: ShopifyAPI.Configuration { get set }
}

public extension ShopifyAPI {
  @discardableResult
  func perform<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    return try await perform(request, allowRetry: true)
  }

  func cached<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    return try await configuration.networkSession.cached(request)
  }
}

private extension ShopifyAPI {
  @discardableResult
  func perform<Model>(_ request: NetworkRequest<Model>, allowRetry: Bool) async throws -> NetworkResponse<Model> {
    do {
      if let accessToken = await auth.token?.accessToken {
        let signedRequest = request.setAuthorizationToken(accessToken)
        return try await configuration.networkSession.perform(signedRequest)
      } else {
        try await authorize()
        return try await perform(request, allowRetry: allowRetry)
      }
    } catch let error as NetworkError {
      if case let .errorStatusCode(code, _) = error, code == 401 {
        do {
          guard allowRetry else {
            throw error
          }
          try await authorize()
          return try await perform(request, allowRetry: false)
        } catch {
          throw error
        }
      }
      assertionFailure(error.localizedDescription)
      throw error
    }
  }

  func authorize() async throws {
    let email = try await configuration.authEmailProvider()
    let requestCodeModel = try await auth.authorize(for: email)
    let code = try await configuration.confirmationCodeProvider()
    try await auth.confirmAuthorization(for: requestCodeModel, with: code)
  }
}

extension NetworkRequest {
  func setAuthorizationToken(_ token: String) -> Self {
    if headers == nil { headers = [:] }
    headers?["Authorization"] = token

    return self
  }
}

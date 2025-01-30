import Foundation
import NetworkSession

public final class UntappdAPI: Sendable {
  let configuration: Configuration

  public let customer: User

  public init() {
    self.configuration = Configuration(basePath: "https://untappd.com")
    self.customer = User(configuration: configuration)
  }
}

public extension UntappdAPI {
  struct Configuration: Sendable {
    public let basePath: String

    public init(basePath: String) {
      self.basePath = basePath
    }
  }
}

public protocol Configurable {
  var configuration: UntappdAPI.Configuration { get set }
}

public extension UntappdAPI {
  @discardableResult
  func perform<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    do {
      return try await NetworkSession.perform(request)
    } catch let error as NetworkError {
      assertionFailure(error.localizedDescription)
      throw error
    }
  }

  func cached<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    return try await NetworkSession.cached(request)
  }
}

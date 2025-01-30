import Foundation
import NetworkSession

public final class BeerRepublicAPI: Sendable {
  let configuration: Configuration

  public let collections: Collections

  public init(configuration: Configuration) {
    self.configuration = configuration
    self.collections = Collections(configuration: configuration)
  }
}

public extension BeerRepublicAPI {
  struct Configuration: Sendable {
    public let networkSession: NetworkSession
    public let basePath: String

    public init(networkSession: NetworkSession, basePath: String = "https://beerrepublic.eu") {
      self.networkSession = networkSession
      self.basePath = basePath
    }
  }
}

public protocol Configurable {
  var configuration: BeerRepublicAPI.Configuration { get set }
}

public extension BeerRepublicAPI {
  @discardableResult
  func perform<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    do {
      return try await configuration.networkSession.perform(request)
    } catch let error as NetworkError {
      throw error
    }
  }

  func cached<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    return try await configuration.networkSession.cached(request)
  }
}

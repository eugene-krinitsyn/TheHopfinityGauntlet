import Foundation

public typealias AuthenticationChallenge = (URLAuthenticationChallenge, (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void

public enum Method: Equatable, CustomStringConvertible {
  case GET, HEAD, POST, PUT, PATCH, DELETE
  case custom(String, hasBody: Bool)

  public var hasBody: Bool {
    switch self {
    case .GET, .HEAD: return false
    case .DELETE, .PATCH, .POST, .PUT: return true
    case let .custom(_, hasBody): return hasBody
    }
  }

  public var description: String {
    switch self {
    case .GET: return "GET"
    case .HEAD: return "HEAD"
    case .POST: return "POST"
    case .PUT: return "PUT"
    case .PATCH: return "PATCH"
    case .DELETE: return "DELETE"
    case let .custom(method, _): return method
    }
  }
}

/**
 Represents a set of parameters with a corresponding encoding.

 Use `.parameters()` function on a `NetworkRequest` object to add parameters to a request.
 */
public enum RequestParameters: Equatable {
  case none
  case query([String: Any])
  case queryItems([URLQueryItem])
  case urlEncoded([String: Any])
  case json([String: Any])
  case multipart([String: String], [String: MultipartFile])
  case data(Data, contentType: String)

  public static func == (lhs: RequestParameters, rhs: RequestParameters) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
      return true
    case let (.query(lhs), .query(rhs)):
      return lhs.keys == rhs.keys
    case let (.urlEncoded(lhs), .urlEncoded(rhs)):
      return lhs.keys == rhs.keys
    case let (.json(lhs), .json(rhs)):
      return lhs.keys == rhs.keys
    case let (.multipart(lhs1, lhs2), .multipart(rhs1, rhs2)):
      return lhs1 == rhs1 && lhs2 == rhs2
    case let (.data(lhs1, lhs2), .data(rhs1, rhs2)):
      return lhs1 == rhs1 && lhs2 == rhs2
    case let (.queryItems(lhs), .queryItems(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }

  public var dictionary: [String: Any] {
    switch self {
    case .none:
      return [:]
    case let .query(query):
      return query
    case let .queryItems(query):
      return query.reduce(into: [String: Any]()) { partialResult, item in
        partialResult[item.name] = item.value
      }
    case let .urlEncoded(encoded):
      return encoded
    case let .json(json):
      return json
    case let .multipart(data, _):
      return data
    case let .data(data, contentType):
      return ["data": contentType]
    }
  }
}

public struct MultipartFile: Equatable {
  public let data: Data
  public let contentType: String
  public let filename: String
  public let name: String

  public init(data: Data, contentType: String, filename: String) {
    self.data = data
    self.contentType = contentType
    self.filename = filename
    self.name = "file"
  }
}

public protocol NetworkRequestPropertySet {
  var URLString: String { get }
  var method: Method { get }
  var parameters: RequestParameters { get }
  var headers: [String: String]? { get }
}

/**
 Use this class to create a request and pass it to `NetworkSession` for a further execution.
 */
public final class NetworkRequest<Model: Decodable>: Equatable, NetworkRequestPropertySet, @unchecked Sendable {
  public let URLString: String

  public init(URLString: String) {
    self.URLString = URLString
  }

  public var method: Method = .GET
  public var parameters: RequestParameters = .none
  public var headers: [String: String]?

  public var disableLocalCache: Bool = false
  public var disableHttpCache: Bool = false

  public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?

  public var authenticationChallenge: AuthenticationChallenge?

  public var timeout: TimeInterval = 60
  public var taskPriority: TaskPriority = .userInitiated
  public var preventRedirects: Bool = false

  /**
   A Boolean value that indicates whether the session should wait for connectivity to become available, or fail immediately.

   Connectivity might be temporarily unavailable for several reasons, including VPN connection requirement.
   */
  public var waitsForConnectivity: Bool = false
  /**
   This property determines the resource timeout interval for all tasks within sessions based on this configuration. The resource timeout interval controls how long (in seconds) to wait for an entire resource to transfer before giving up. The resource timer starts when the request is initiated and counts until either the request completes or this timeout interval is reached, whichever comes first.

   The default value is 7 days.
   */
  public var timeoutIntervalForResource: TimeInterval?
  /**
   Setting this to true will produce a cURL into console log. Default value is false.
   */
  public var isLoggingEnabled: Bool = false

  public static func == (lhs: NetworkRequest<Model>, rhs: NetworkRequest<Model>) -> Bool {
    lhs.URLString == rhs.URLString &&
      lhs.method == rhs.method &&
      lhs.parameters == rhs.parameters &&
      lhs.headers == rhs.headers &&
      lhs.disableLocalCache == rhs.disableLocalCache &&
      lhs.disableHttpCache == rhs.disableHttpCache &&
      lhs.timeout == rhs.timeout &&
      lhs.taskPriority == rhs.taskPriority &&
      lhs.waitsForConnectivity == rhs.waitsForConnectivity
  }
}

// MARK: - Builder

public extension NetworkRequest {
  @discardableResult
  func setMethod(_ value: Method) -> Self {
    method = value
    return self
  }

  @discardableResult
  func setParameters(_ value: RequestParameters) -> Self {
    parameters = value
    return self
  }

  @discardableResult
  func setHeaders(_ value: [String: String]?) -> Self {
    headers = value
    return self
  }

  @discardableResult
  func setDisableLocalCache(_ value: Bool) -> Self {
    disableLocalCache = value
    return self
  }

  @discardableResult
  func setDisableHttpCache(_ value: Bool) -> Self {
    disableHttpCache = value
    return self
  }

  @discardableResult
  func setDisableCache(_ value: Bool) -> Self {
    disableLocalCache = value
    disableHttpCache = value
    return self
  }

  @discardableResult
  func setDateDecodingStrategy(_ value: JSONDecoder.DateDecodingStrategy) -> Self {
    dateDecodingStrategy = value
    return self
  }

  @discardableResult
  func setAuthenticationChallenge(_ value: @escaping AuthenticationChallenge) -> Self {
    authenticationChallenge = value
    return self
  }

  @discardableResult
  func setTimeout(_ value: TimeInterval) -> Self {
    timeout = value
    return self
  }

  @discardableResult
  func setTaskPriority(_ value: TaskPriority) -> Self {
    taskPriority = value
    return self
  }

  @discardableResult
  func setWaitsForConnectivity(_ value: Bool) -> Self {
    waitsForConnectivity = value
    return self
  }

  @discardableResult
  func setTimeoutIntervalForResource(_ value: TimeInterval?) -> Self {
    timeoutIntervalForResource = value
    return self
  }

  @discardableResult
  func setIsLoggingEnabled(_ value: Bool) -> Self {
    isLoggingEnabled = value
    return self
  }

  @discardableResult
  func setPreventRedirects(_ value: Bool) -> Self {
    preventRedirects = value
    return self
  }
}

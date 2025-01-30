import Foundation

public final class NetworkSession: Sendable {
  public static let shared: NetworkSession = .init()

  public let urlSession: URLSession
  let delegate = SessionDelegate()

  public init(with configuration: URLSessionConfiguration = .default) {
    self.urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
  }
}

// MARK: - Request execution

public extension NetworkSession {
  func perform<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    delegate.preventRedirects = request.preventRedirects
    return try await withCheckedThrowingContinuation { [weak self] continuation in
      Task.detached(priority: request.taskPriority) { [weak self] in
        guard let self else { return }
        do {
          let (data, response) = try await self.execute(request: request, localCache: false)
          let type: ResponseType = response.resultFromHTTPCache && !request.disableHttpCache ? .httpCache : .regular
          let parsed = try Self.parse(data: data, response: response, responseType: type, for: request)
          continuation.resume(returning: parsed)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  static func perform<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    try await withCheckedThrowingContinuation { continuation in
      Task.detached(priority: request.taskPriority) {
        do {
          let (data, response) = try await execute(request: request, localCache: false)
          let type: ResponseType = response.resultFromHTTPCache && !request.disableHttpCache ? .httpCache : .regular
          let parsed = try parse(data: data, response: response, responseType: type, for: request)
          continuation.resume(returning: parsed)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func cached<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    try await withCheckedThrowingContinuation { [weak self] continuation in
      Task.detached(priority: request.taskPriority) { [weak self] in
        guard let self else { return }
        do {
          let (data, response) = try await self.execute(request: request, localCache: true)
          let parsed = try Self.parse(data: data, response: response, responseType: .localCache, for: request)
          continuation.resume(returning: parsed)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  static func cached<Model>(_ request: NetworkRequest<Model>) async throws -> NetworkResponse<Model> {
    try await withCheckedThrowingContinuation { continuation in
      Task.detached(priority: request.taskPriority) {
        do {
          let (data, response) = try await execute(request: request, localCache: true)
          let parsed = try parse(data: data, response: response, responseType: .localCache, for: request)
          continuation.resume(returning: parsed)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

// MARK: - Private

private extension NetworkSession {
  func execute(
    request: NetworkRequest<some Any>,
    localCache: Bool
  ) async throws -> (Data, HTTPURLResponse) {
    try await Self.execute(session: urlSession, request: request, localCache: localCache)
  }

  static func execute(
    request: NetworkRequest<some Any>,
    localCache: Bool
  ) async throws -> (Data, HTTPURLResponse) {
    let delegate = SessionDelegate()
    delegate.authenticationChallenge = request.authenticationChallenge
    delegate.preventRedirects = request.preventRedirects

    let policy = cachePolicy(for: request, localCache: localCache)
    let session = URLSession(configuration: configuration(with: policy, and: request), delegate: delegate, delegateQueue: nil)

    return try await execute(session: session, request: request, localCache: localCache)
  }

  static func execute(
    session: URLSession,
    request: NetworkRequest<some Any>,
    localCache: Bool
  ) async throws -> (Data, HTTPURLResponse) {
    let policy = cachePolicy(for: request, localCache: localCache)

    let urlRequest = try prepareURLRequest(from: request, cachePolicy: policy)

    if request.isLoggingEnabled, !localCache {
      print(URLRequestFormatter.cURLCommand(from: urlRequest))
    }

    let (data, response) = try await session.data(for: urlRequest)

    guard let response = response as? HTTPURLResponse else {
      throw NetworkError.nonHTTPResponse(response: response)
    }

    guard (200 ..< 400) ~= response.statusCode else {
      throw NetworkError.errorStatusCode(response.statusCode, data)
    }

    return (data, response)
  }

  static func parse<Model>(
    data: Data,
    response httpResponse: HTTPURLResponse,
    responseType: ResponseType,
    for request: NetworkRequest<Model>
  ) throws -> NetworkResponse<Model> {
    let decoder = JSONDecoder()
    request.dateDecodingStrategy.map { decoder.dateDecodingStrategy = $0 }
    let headers: [String: String] = (httpResponse.allHeaderFields as? [String: String]) ?? [:]

    var data: Data = data
    if data.isEmpty {
      data = "{}".data(using: .utf8) ?? Data()
    }

    do {
      let result = try decoder.decode(Model.self, from: data)
      let response = NetworkResponse(
        result: result,
        type: responseType,
        headers: headers,
        statusCode: httpResponse.statusCode
      )
      return response
    } catch let decodingError {
      let contentType = headers["Content-Type"]?.lowercased() ?? ""
      guard contentType.contains("text/html") else {
        throw NetworkError.unableToParseModel(
          BetterDecodingError(with: decodingError), data, httpResponse
        )
      }

      do {
        let rawHTMLString = String(data: data, encoding: .utf8) ?? ""

        // escape backslashes
        var escaped = rawHTMLString.replacingOccurrences(of: "\\", with: "\\\\")
        // escape double quotes
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        // escape newlines
        escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")
        // might also want to escape carriage returns if present:
        escaped = escaped.replacingOccurrences(of: "\r", with: "\\r")
        // escape tabs
        escaped = escaped.replacingOccurrences(of: "\t", with: "\\t")

        // wrap in quotes to make it a valid JSON string
        let wrappedJSONString = "\"\(escaped)\""

        guard let wrappedData = wrappedJSONString.data(using: .utf8) else {
          throw NetworkError.unableToParseModel(
            BetterDecodingError(with: decodingError), data, httpResponse
          )
        }

        let result = try decoder.decode(Model.self, from: wrappedData)

        let response = NetworkResponse(
          result: result,
          type: responseType,
          headers: headers,
          statusCode: httpResponse.statusCode
        )
        return response
      } catch {
        let decodingError = BetterDecodingError(with: error)
        throw NetworkError.unableToParseModel(decodingError, data, httpResponse)
      }
    }
  }
}

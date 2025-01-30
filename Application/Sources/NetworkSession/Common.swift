import Foundation

typealias DataAndResponse = (data: Data, response: HTTPURLResponse)

extension HTTPURLResponse {
  private static let cacheFlagKey = "X-ResultFromHttpCache"

  var httpCachedResponse: HTTPURLResponse? {
    guard let url else { return nil }
    var headers = allHeaderFields as? [String: String] ?? [:]
    headers[HTTPURLResponse.cacheFlagKey] = "true"
    return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)
  }

  var resultFromHTTPCache: Bool {
    guard let headers = allHeaderFields as? [String: String] else { return false }
    return headers[HTTPURLResponse.cacheFlagKey] == "true"
  }
}

func cachePolicy(for request: NetworkRequest<some Any>, localCache: Bool) -> URLRequest.CachePolicy {
  if localCache {
    if request.disableLocalCache { assertionFailure("local cache was disabled in request") }
    return .returnCacheDataDontLoad
  } else {
    return request.disableHttpCache ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
  }
}

func prepareURLRequest(from request: NetworkRequest<some Any>, cachePolicy: URLRequest.CachePolicy) throws -> URLRequest {
  guard let requestURL = URL(string: request.URLString) else {
    throw NetworkError.invalidURL(request.URLString)
  }

  var urlRequest = URLRequest(url: requestURL, cachePolicy: cachePolicy, timeoutInterval: request.timeout)
  urlRequest.httpMethod = request.method.description
  if let headers = request.headers {
    for (key, value) in headers {
      urlRequest.setValue(value, forHTTPHeaderField: key)
    }
  }

  switch (request.method.hasBody, request.parameters) {
  case (_, .none):
    urlRequest.url = try prepareURL(with: requestURL, params: nil)
  case let (_, .query(params)):
    urlRequest.url = try prepareURL(with: requestURL, params: params)
  case let (_, .queryItems(items)):
    guard var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: true) else {
      throw NetworkError.invalidRelativeURL(requestURL)
    }
    var queryItems: [URLQueryItem] = items
    queryItems.append(contentsOf: components.queryItems ?? [])
    components.queryItems = queryItems
    urlRequest.url = components.url
  case (false, _):
    assertionFailure("\(request.method.description) request can't have a body")
  case (true, let .urlEncoded(params)):
    let queryItems = prepare(value: params, with: nil)
    var components = URLComponents()
    components.queryItems = queryItems
    urlRequest.httpBody = components.percentEncodedQuery?.data(using: String.Encoding.utf8)
    urlRequest.url = try prepareURL(with: requestURL, params: nil)
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
  case (true, let .json(params)):
    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.url = try prepareURL(with: requestURL, params: nil)
  case (true, let .multipart(form, files)):
    let (data, contentType) = try prepareMultipartData(with: form, files)
    urlRequest.httpBody = data
    urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
    urlRequest.url = try prepareURL(with: requestURL, params: nil)
  case (true, let .data(data, contentType)):
    urlRequest.httpBody = data
    urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
    urlRequest.url = try prepareURL(with: requestURL, params: nil)
  }

  return urlRequest
}

func prepareURL(with url: URL, params: [String: Any]?) throws -> URL {
  var queryItems = [URLQueryItem]()
  if let params {
    queryItems.append(contentsOf: prepare(value: params, with: nil))
  }

  guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
    throw NetworkError.invalidRelativeURL(url)
  }

  queryItems.append(contentsOf: components.queryItems ?? [])
  components.queryItems = queryItems.count > 0 ? queryItems : nil
  guard let url = components.url else {
    throw NetworkError.invalidURLComponents(components)
  }
  return url
}

private func prepare(value: Any, with key: String?) -> [URLQueryItem] {
  switch value {
  case let dictionary as [String: Any]:
    return dictionary.sorted { $0.0 < $1.0 }.flatMap { nestedKey, nestedValue -> [URLQueryItem] in
      if let key {
        return prepare(value: nestedValue, with: "\(key)[\(nestedKey)]")
      } else {
        return prepare(value: nestedValue, with: nestedKey)
      }
    }
  case let array as [Any]:
    if let key {
      return array.flatMap { prepare(value: $0, with: "\(key)[]") }
    } else {
      return []
    }
  case let string as String:
    if let key {
      return [URLQueryItem(name: key, value: string)]
    } else {
      return []
    }
  case let stringConvertible as CustomStringConvertible:
    if let key {
      return [URLQueryItem(name: key, value: stringConvertible.description)]
    } else {
      return []
    }
  default: return []
  }
}

func prepareMultipartData(with form: [String: String], _ files: [String: MultipartFile]) throws -> (data: Data, contentType: String) {
  let boundary = "__X_CLYX_BOUNDARY__"
  var data = Data()
  let boundaryData = "--\(boundary)\r\n".data(using: .utf8)!

  for (key, value) in form.sorted(by: { $0.key < $1.key }) {
    data.append(boundaryData)

    guard let dispositionData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) else {
      assertionFailure("can't encode key \(key)")
      continue
    }
    data.append(dispositionData)

    guard let valueData = (value + "\r\n").data(using: .utf8) else {
      assertionFailure("can't encode value \(value)")
      continue
    }
    data.append(valueData)
  }

  for (key, file) in files.sorted(by: { $0.key < $1.key }) {
    data.append(boundaryData)

    guard let dispositionData = "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.filename)\"\r\n"
      .data(using: .utf8)
    else {
      assertionFailure("can't encode key \(key)")
      continue
    }
    data.append(dispositionData)

    guard let contentTypeData = "Content-Type: \(file.contentType)\r\n\r\n".data(using: .utf8) else {
      assertionFailure("can't encode content-type \(file.contentType)")
      continue
    }
    data.append(contentTypeData)
    data.append(file.data)

    data.append("\r\n".data(using: .utf8)!)
  }

  data.append("--\(boundary)--\r\n".data(using: .utf8)!)
  return (data, "multipart/form-data; boundary=\(boundary)")
}

import Foundation

func configuration(with policy: URLRequest.CachePolicy, and request: NetworkRequest<some Any>) -> URLSessionConfiguration {
  let configuration = URLSessionConfiguration.default
  configuration.requestCachePolicy = policy
  configuration.waitsForConnectivity = request.waitsForConnectivity
  if let timeoutIntervalForResource = request.timeoutIntervalForResource {
    configuration.timeoutIntervalForResource = timeoutIntervalForResource
  }
  configuration.timeoutIntervalForRequest = request.timeout
  return configuration
}

final class SessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
  var authenticationChallenge: AuthenticationChallenge?
  var preventRedirects: Bool = false

  private var response: URLResponse?
  private var data = Data()

  func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    if let authenticationChallenge {
      authenticationChallenge(challenge, completionHandler)
    } else {
      completionHandler(.performDefaultHandling, nil)
    }
  }

  func urlSession(
    _: URLSession,
    dataTask _: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    self.response = response
    if response.expectedContentLength > 0 {
      data.reserveCapacity(Int(response.expectedContentLength))
    }

    completionHandler(.allow)
  }

  func urlSession(
    _: URLSession,
    dataTask _: URLSessionDataTask,
    willCacheResponse cached: CachedURLResponse,
    completionHandler: @escaping (CachedURLResponse?) -> Void
  ) {
    if let response = cached.response as? HTTPURLResponse, let updated = response.httpCachedResponse {
      let newCached = CachedURLResponse(
        response: updated,
        data: cached.data,
        userInfo: cached.userInfo,
        storagePolicy: cached.storagePolicy
      )
      completionHandler(newCached)
    } else {
      completionHandler(cached)
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) {
    completionHandler(preventRedirects ? nil : request)
  }
}

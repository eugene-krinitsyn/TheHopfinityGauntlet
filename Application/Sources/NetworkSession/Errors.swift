import Foundation

public enum NetworkError {
  case undefined(message: String?)
  case badServerResponse(response: URLResponse?)
  case nonHTTPResponse(response: URLResponse)
  case unableToParseModel(BetterDecodingError, Data, HTTPURLResponse)
  case errorStatusCode(Int, Data)
  case invalidURL(String)
  case invalidRelativeURL(URL)
  case invalidURLComponents(URLComponents)
}

// MARK: LocalizedError

extension NetworkError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .undefined(message):
      if let message {
        return "Unknown network error: \(message)"
      } else {
        return "Unknown network error"
      }
    case .badServerResponse:
      return "Server has returned unexpected response"
    case let .nonHTTPResponse(response):
      return "Response type is not HTTP: \(response.description)"
    case let .unableToParseModel(error, _, _):
      return "Failed to parse the reponse: \(error.localizedDescription)"
    case let .errorStatusCode(int, _):
      return "Network error with status code \(int)"
    case let .invalidURL(string):
      return "Invalid URL: \(string)"
    case let .invalidRelativeURL(uRL):
      return "Invalid relative URL: \(uRL)"
    case let .invalidURLComponents(uRLComponents):
      return "Invalid URL components: \(uRLComponents.description)"
    }
  }
}

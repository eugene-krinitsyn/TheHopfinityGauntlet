import Foundation
import NetworkSession

public extension UntappdAPI {
  struct User: Configurable, Sendable {
    public var configuration: UntappdAPI.Configuration
  }
}

public extension UntappdAPI.User {
  func requestUserCheckinSearch(for username: String, with query: String) -> NetworkRequest<CheckinSearchResultsModel> {
    let url = configuration.basePath + "/user/\(username)/beers"
    return NetworkRequest(URLString: url)
      .setParameters(.query([
        "q": query
      ]))
  }
}

import Foundation
import NetworkSession

public extension BeerRepublicAPI {
  struct Collections: Configurable, Sendable {
    public var configuration: BeerRepublicAPI.Configuration
  }
}

public extension BeerRepublicAPI.Collections {
  func requestFilters() -> NetworkRequest<FiltersModel> {
    let url = configuration.basePath + "/collections/all-beers"
    return NetworkRequest(URLString: url)
      .setIsLoggingEnabled(true)
  }

  func requestBeers(filters: [String: [String]]? = nil, priceLimit: Int? = nil, page: Int) -> NetworkRequest<CollectionModel> {
    let url = configuration.basePath + "/collections/all-beers"
    var params: [URLQueryItem] = [
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "sort_by", value: "created-descending")
    ]
    priceLimit.map {
      params.append(URLQueryItem(name: "filter.v.price.lte", value: "\($0)"))
    }
    filters?.forEach { filter in
      filter.value.forEach { value in
        params.append(URLQueryItem(name: "filter.p.m.my_fields.\(filter.key)", value: "\(value)"))
      }
    }

    return NetworkRequest(URLString: url)
      .setParameters(.queryItems(params))
      .setIsLoggingEnabled(true)
  }

  func requestBeerDetails(url: String) -> NetworkRequest<ExpirationDateModel> {
    let url = configuration.basePath + url
    return NetworkRequest(URLString: url)
  }
}

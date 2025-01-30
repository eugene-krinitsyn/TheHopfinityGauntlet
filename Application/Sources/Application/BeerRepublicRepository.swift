import Foundation
import NetworkSession
import BeerRepublicAPI
import UntappdAPI

actor BeerRepublicRepository {

  private let networkSession = NetworkSession.shared

  private let untappdAPI = UntappdAPI()

  private lazy var beerRepublicAPI: BeerRepublicAPI = {
    BeerRepublicAPI(configuration: BeerRepublicAPI.Configuration(networkSession: networkSession))
  }()

//  lazy var shopifyAPI: ShopifyAPI = {
//    ShopifyAPI(
//      configuration: .init(
//        networkSession: networkSession,
//        basePath: "https://account.beerrepublic.eu",
//        shopifyDomain: "firma-bier.myshopify.com",
//        authEmailProvider: requestAuthEmail,
//        confirmationCodeProvider: requestConfirmationCode
//      )
//    )
//  }()

  func getFilters() async throws -> [String: [String]] {
    let request = beerRepublicAPI.collections.requestFilters()
    let response = try await beerRepublicAPI.perform(request)
    return response.result.filters
  }

  func getBeers(
    filters: [String: [String]],
    untappdUsername: String? = nil,
    priceLimit: Int? = nil,
    orderLimit: Int? = nil,
    quantityLimit: Int? = nil,
    expirationDateLimit: Date? = nil
  ) async throws -> [BeerRepublicItem] {
    var collections: [CollectionModel] = []
    var lastPage: Int?
    var currentPage: Int = 0
    repeat {
      currentPage += 1
      let collection = try await getBeers(page: currentPage, filters: filters, priceLimit: priceLimit)
      collections.append(collection)
      if lastPage == nil {
        lastPage = collection.lastPage ?? 1
      }
    } while lastPage != currentPage

    let products = collections.flatMap(\.products)
    var beerItems: [BeerRepublicItem] = []
    if let expirationDateLimit {
      for product in products {
        let expirationDate = try await getExpirationForBeer(product)
        if let expirationDate, expirationDate > expirationDateLimit {
          beerItems.append(BeerRepublicItem(product: product, expirationDate: expirationDate))
        }
      }
    } else {
      beerItems = products.map { BeerRepublicItem(product: $0, expirationDate: nil) }
    }

    var checkedBeerItems: [BeerRepublicItem] = []
    var orderPrice: Int = 0
    for beerItem in beerItems {
      var haveNotHad: Bool = false
      if let untappdUsername, !untappdUsername.isEmpty {
        let checkin = try await getCheckinSearchResults(for: untappdUsername, with: beerItem.product)
        haveNotHad = checkin.results.isEmpty
      }
      guard haveNotHad else {
        continue
      }
      checkedBeerItems.append(beerItem)
      orderPrice += Int(beerItem.product.price.amount.rounded(.up))
      if let orderLimit, orderPrice >= orderLimit {
        break
      }
    }
    return checkedBeerItems
  }

  func getCartLink(for beers: [BeerRepublicItem]) -> URL? {
    let path: String = beers
      .map { "\($0.product.id):1" }
      .joined(separator: ",")
    let urlString = "https://beerrepublic.eu/cart/\(path)?attributes%5Bfrom%5D=new-customer-accounts&storefront=true"
    return URL(string: urlString)
  }
}

// MARK: - Requests

private extension BeerRepublicRepository {
  func getBeers(page: Int, filters: [String: [String]], priceLimit: Int? = nil) async throws -> CollectionModel {
    let request = beerRepublicAPI.collections.requestBeers(
      filters: filters,
      priceLimit: priceLimit,
      page: page
    )
    let response = try await beerRepublicAPI.perform(request)
    return response.result
  }

  func getExpirationForBeer(_ product: ProductModel) async throws -> Date? {
    let request = beerRepublicAPI.collections.requestBeerDetails(url: product.product.url)
    let response = try? await beerRepublicAPI.perform(request)
    return response?.result.date
  }

//  func getPreviousOrders() async throws -> OrdersModel {
//    let request = shopifyAPI.customer.requestOrders()
//    let response = try await shopifyAPI.perform(request)
//    return response.result
//  }

  func getCheckinSearchResults(for untappdUsername: String, with product: ProductModel) async throws -> CheckinSearchResultsModel {
    let request = untappdAPI.customer.requestUserCheckinSearch(
      for: untappdUsername,
      with: product.product.title
    )
    let response = try await untappdAPI.perform(request)
    return response.result
  }
}

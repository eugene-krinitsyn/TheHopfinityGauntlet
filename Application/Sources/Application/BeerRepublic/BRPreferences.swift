import Foundation

struct BRPreferences: Equatable {
  var selectedFilters: [String: [String]] = [:]
  var untappdUsername: String = ""
  var priceLimit: String = ""
  var orderLimit: String = ""
  var quantityLimit: String = ""
  var expirationDate: Date = .init()

  private let keyPrefix = "beerrepublic_"

  init() {
    selectedFilters = UserDefaults.standard.object(forKey: keyPrefix + "filters") as? [String: [String]] ?? [:]
    untappdUsername = UserDefaults.standard.string(forKey: keyPrefix + "untappd_username") ?? ""
    priceLimit = UserDefaults.standard.string(forKey: keyPrefix + "price_limit") ?? ""
    orderLimit = UserDefaults.standard.string(forKey: keyPrefix + "order_limit") ?? ""
    quantityLimit = UserDefaults.standard.string(forKey: keyPrefix + "quantity_limit") ?? ""
    expirationDate = UserDefaults.standard.object(forKey: keyPrefix + "expiration_date") as? Date ?? .init()
  }

  mutating func selectFilter(_ filter: String, type: String) {
    if var selectedType = selectedFilters[type] {
      if let index = selectedType.firstIndex(of: filter) {
        selectedType.remove(at: index)
      } else {
        selectedType.append(filter)
      }
      selectedFilters[type] = selectedType.isEmpty ? nil : selectedType
    } else {
      selectedFilters[type] = [filter]
    }
  }

  func getUsername() -> String? {
    let string = untappdUsername.trimmingCharacters(in: .whitespacesAndNewlines)
    return string.isEmpty ? nil : string
  }

  func getPriceLimit() -> Int? {
    Int(priceLimit)
  }

  func getOrderLimit() -> Int? {
    Int(orderLimit)
  }

  func getQuantityLimit() -> Int? {
    Int(quantityLimit)
  }

  func getExpirationDate() -> Date? {
    Calendar.current.isDateInToday(expirationDate) ? nil : expirationDate
  }
}

extension BRPreferences {
  func save() {
    UserDefaults.standard.set(selectedFilters, forKey: keyPrefix + "filters")
    UserDefaults.standard.set(untappdUsername, forKey: keyPrefix + "untappd_username")
    UserDefaults.standard.set(priceLimit, forKey: keyPrefix + "price_limit")
    UserDefaults.standard.set(orderLimit, forKey: keyPrefix + "order_limit")
    UserDefaults.standard.set(quantityLimit, forKey: keyPrefix + "quantity_limit")
    UserDefaults.standard.set(expirationDate, forKey: keyPrefix + "expiration_date")
  }
}

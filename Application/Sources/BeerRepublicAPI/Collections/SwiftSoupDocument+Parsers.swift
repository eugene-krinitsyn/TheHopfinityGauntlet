import Foundation
import SwiftSoup
import NetworkSession

extension Document {
  func getFilters() throws -> [String: [String]] {
    // 1) Select all relevant checkboxes (class="checkbox", name starts with "filter.p.m.my_fields.")
    //    Adjust your selector as needed if the site changes their markup.
    let inputElements = try select("input[type=checkbox].checkbox[name^=filter.p.m.my_fields.]")

    var parsedFilters: [String: [String]] = [:]

    // 2) Iterate over each checkbox
    for input in inputElements {
      // e.g. "filter.p.m.my_fields.type", "filter.p.m.my_fields.origin"
      let fullName = try input.attr("name")

      // Extract the substring after "filter.p.m.my_fields."
      // This should give you "type", "origin", "untappd", etc.
      let filterCategory = fullName.replacingOccurrences(
        of: "filter.p.m.my_fields.",
        with: ""
      )

      // 3) Get the value attribute, e.g. "Altbier", "Canada", "⭐ ⭐ ⭐ ⭐ ⭐ (4.0 - 5.0)"
      let filterValue = try input.attr("value")

      // 4) Store it in a dictionary [String: [String]]
      //    so you can collect all values under each filter category.
      parsedFilters[filterCategory, default: []].append(filterValue)
    }

    return parsedFilters.mapValues { Array(Set($0)) }
  }

  func getCollectionJSON() throws -> String {
    // 1) Select the target <script> block
    guard let scriptElement = try select("#web-pixels-manager-setup").first() else {
      throw NetworkError.undefined(message: "Couldn't find collection element")
    }

    // 2) Get the JS content
    let scriptContent = try scriptElement.html()

    // 3) Extract the JSON within webPixelsManagerAPI.publish("collection_viewed", {...});
    //    We'll do it with either substring or regex. Below is a regex approach:
    let pattern = #"""
        webPixelsManagerAPI\.publish\(\s*"collection_viewed"\s*,\s*(\{.*?\})\);
        """#
    // Explanation:
    // - We look for: webPixelsManagerAPI.publish("collection_viewed",
    // - Then capture (\{.*?\}) in a non-greedy way, up to the semicolon/closing parenthesis.
    // The `\.publish\(` etc. are escaped as needed for the regex engine.
    // We enable dot-matches-newline so `.*?` can cross multiple lines.

    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
      throw NetworkError.undefined(message: "Couldn't parse collection HTML")
    }

    let range = NSRange(scriptContent.startIndex..<scriptContent.endIndex, in: scriptContent)

    // Attempt to find the first match (you could loop if you suspect multiple)
    guard let match = regex.firstMatch(in: scriptContent, options: [], range: range) else {
      throw NetworkError.undefined(message: "Couldn't parse collection HTML")
    }

    // Our capture group #1 is the JSON object
    let jsonRange = match.range(at: 1)
    guard let swiftRange = Range(jsonRange, in: scriptContent) else {
      throw NetworkError.undefined(message: "Couldn't parse collection HTML")
    }

    let jsonSnippet = String(scriptContent[swiftRange])

    // We hope this snippet is valid JSON: e.g. {"collection":{...}}
    return jsonSnippet
  }

  func getLastPage() throws -> Int {
    // Select all <a ... data-page="xxx"> inside the pagination__nav div
    let paginationLinks = try select("div.pagination__nav a[data-page]")

    // Extract the page numbers by reading each element’s data-page attribute
    // and converting it to an Int.
    let pageNumbers: [Int] = try paginationLinks.compactMap { element in
        // e.g. "1", "3", "52", etc.
        let pageStr = try element.attr("data-page")
        return Int(pageStr)
    }

    // Return the highest page number found
    if let max = pageNumbers.max() {
      return max
    } else {
      throw NetworkError.undefined(message: "Couldn't find pagination")
    }
  }

  static let expirationFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.dateFormat = "yyyy-MM-dd"
    return f
  }()

  func getExpirationDate() throws -> Date {
    // This will select any <time> element that has a `datetime` attribute:
    guard let timeElement = try select("time[datetime]").first() else {
      throw NetworkError.undefined(message: "Couldn't find time[datetime]")
    }

    // Extract the attribute (e.g. "2025-11-21")
    let dateString = try timeElement.attr("datetime")
    guard let date = Self.expirationFormatter.date(from: dateString) else {
      throw NetworkError.undefined(message: "Couldn't parse time[datetime]")
    }
    return date
  }
}

private extension String {
  func extractJSON() -> String? {
    // We look for: var meta = { ...some JSON... };
    // We'll use a lazy-dot `.*?` with "dot matches newline" if needed:
    // This pattern says:
    //   - "var meta = " literally
    //   - then capture "(\\{.*?\\})" i.e. { ... } in a non-greedy way
    //   - possibly followed by a semicolon
    // Make sure to enable "dot matches newline" if the JSON can have line breaks.

    let pattern = #"var meta\s*=\s*(\{.*?\});"#
    // or you can try: "var meta\\s*=\\s*(\\{.*?\\});"
    // depending on the Swift version and raw string syntax

    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
      return nil
    }

    let range = NSRange(self.startIndex..<self.endIndex, in: self)
    if let match = regex.firstMatch(in: self, options: [], range: range) {
      // Capture group 1 is our JSON object in braces { ... }
      if let jsonRange = Range(match.range(at: 1), in: self) {
        let jsonSnippet = String(self[jsonRange])
        return jsonSnippet
      }
    }
    return nil
  }
}

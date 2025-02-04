import Foundation
import SwiftUI

public enum Mock {
  public static func id() -> String {
    UUID().uuidString
  }

  public static func name(isLong: Bool = false) -> String {
    let numbersRange: ClosedRange<Int> = isLong ? (100 ... 199) : (20 ... 99)
    let dividingBy: Int = isLong ? 100 : 10
    let placeholderValue: Int = isLong ? 978 : 78
    let randomNumber = numbersRange
      .compactMap { $0.quotientAndRemainder(dividingBy: dividingBy).remainder > 0 ? $0 : nil }
      .randomElement() ?? placeholderValue
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .spellOut
    let name = numberFormatter.string(from: NSNumber(integerLiteral: randomNumber))!
    return name.capitalized
  }

  public static func description() -> String {
    let placeholder = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
    """
    let randomPosition = Int.random(in: 0 ... placeholder.count)
    let randomlyPrefixed = placeholder.prefix(randomPosition)
    return String(randomlyPrefixed)
  }

  public enum DateType: CaseIterable, Equatable {
    case past, future
  }

  public static func date(of types: [DateType] = DateType.allCases, isNearest: Bool = true) -> Date {
    let pastDate: Date
    let futureDate: Date
    if isNearest {
      pastDate = Calendar.current.date(byAdding: .weekOfMonth, value: -1, to: Date())!
      futureDate = Calendar.current.date(byAdding: .weekOfMonth, value: 1, to: Date())!
    } else {
      pastDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
      futureDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
    }

    let spanStart: TimeInterval = types.contains(.past) ? pastDate.timeIntervalSinceNow : 0
    let spanEnd: TimeInterval = types.contains(.future) ? futureDate.timeIntervalSinceNow : 0
    let span = TimeInterval.random(in: spanStart ... spanEnd)
    return Date(timeIntervalSinceNow: span)
  }
}

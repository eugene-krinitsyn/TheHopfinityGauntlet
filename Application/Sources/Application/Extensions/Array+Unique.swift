import Foundation

extension Array where Element: Equatable  {
  mutating func appendUnique<S>(contentsOf newElements: S) where Element == S.Element, S: Sequence {
    newElements.forEach { element in
      guard !contains(element) else { return }
      append(element)
    }
  }
}

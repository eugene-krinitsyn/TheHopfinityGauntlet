import Foundation
import Combine

@MainActor
final class SplitStore: ObservableObject, Sendable {
  @Published private(set) var presetsStore = BRPresetsStore()
  @Published private(set) var resultsStore: BRResultsStore?

  private var cancellables = Set<AnyCancellable>()

  init(presetsStore: BRPresetsStore) {
    self.presetsStore = presetsStore
    presetsStore.$searchResults
      .receive(on: RunLoop.main)
      .sink { [weak self] searchResults in
        guard let searchResults else { return }
        self?.resultsStore = BRResultsStore(beers: searchResults)
      }
      .store(in: &cancellables)
  }
}

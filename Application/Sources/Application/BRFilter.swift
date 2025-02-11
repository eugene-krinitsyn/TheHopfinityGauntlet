struct BRFilter: Identifiable, Equatable {
  var id: String { key }
  let key: String
  let values: [String]
}

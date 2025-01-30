// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Application",
  defaultLocalization: "en",
  platforms: [.iOS(.v18), .macOS(.v11)],
  products: Product.allProducts,
  dependencies: Package.Dependency.allDependencies,
  targets: Target.allTargets
)

struct ExternalDependency: @unchecked Sendable {
  let product: Target.Dependency
  let package: Package.Dependency
}

struct Module: @unchecked Sendable {
  let name: String
  var moduleDependencies: [Module] = []
  var externalDependencies: [ExternalDependency] = []
  var resources: [Resource]?
  var settings: [SwiftSetting]?
  var plugins: [Target.PluginUsage]?
  var isTestTarget = false
}

// MARK: - External Dependencies

extension ExternalDependency {
  static let kingfisher = ExternalDependency(
    product: .product(name: "Kingfisher", package: "Kingfisher"),
    package: .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
  )

  static let swiftAsyncAlgorithms = ExternalDependency(
    product: .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
    package: .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "0.0.4")
  )

  static let swiftSoup = ExternalDependency(
    product: .product(name: "SwiftSoup", package: "SwiftSoup"),
    package: .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.5")
  )
}

// MARK: - Modules
extension Module {

  // MARK: - Core
  static let application = Module(
    name: "Application",
    moduleDependencies: [
      networkSession,
      beerRepublicAPI,
      shopifyAPI,
      untappdAPI
    ],
    externalDependencies: [
      .kingfisher,
      .swiftAsyncAlgorithms
    ],
    resources: [
      //.process("Resources")
    ]
  )

  static let networkSession = Module(
    name: "NetworkSession"
  )

  static let beerRepublicAPI = Module(
    name: "BeerRepublicAPI",
    moduleDependencies: [.networkSession],
    externalDependencies: [.swiftSoup]
  )

  static let shopifyAPI = Module(
    name: "ShopifyAPI",
    moduleDependencies: [.networkSession],
    externalDependencies: [.swiftSoup]
  )

  static let untappdAPI = Module(
    name: "UntappdAPI",
    moduleDependencies: [.networkSession],
    externalDependencies: [.swiftSoup]
  )

  static let appModules: [Module] = [
    application,
    networkSession,
    beerRepublicAPI,
    shopifyAPI,
    untappdAPI
  ]
}

// MARK: - Package configuration

extension Product {
  static var allProducts: [Product] {
    Module.appModules.compactMap { module -> Product? in
      module.isTestTarget ? nil : Product.library(name: module.name, targets: [module.name])
    }
  }
}

extension Package.Dependency {
  static var allDependencies: [Package.Dependency] {
    Module.appModules
      .flatMap(\.externalDependencies)
      .map(\.package)
      .uniqueElements(by: \.kind)
  }
}

extension Target {
  static var allTargets: [Target] {
    Module.appModules.map { module in
      let moduleDependencies = module.moduleDependencies.map(\.name).map(Target.Dependency.init(stringLiteral:))
      let externalDependencies = module.externalDependencies.map(\.product)

      let dependencies = moduleDependencies + externalDependencies

      if module.isTestTarget {
        return .testTarget(
          name: module.name,
          dependencies: dependencies,
          resources: module.resources
        )
      } else {
        return .target(
          name: module.name,
          dependencies: dependencies,
          resources: module.resources,
          plugins: module.plugins
        )
      }
    }
  }
}

// MARK: - Extensions

/// We use ``Array.uniqueElements(by:)`` and ``Package.Dependency.Kind`` conforming to ``Equatable``
/// to filter only **unique** packages when we add external dependencies into package.
extension Array {
  func uniqueElements<T: Equatable>(by keyPath: KeyPath<Element, T>) -> [Element] {
    var uniqueElements: [Element] = []
    for value in self {
      let isThereElementAlready = uniqueElements.contains { element in
        element[keyPath: keyPath] == value[keyPath: keyPath]
      }
      guard isThereElementAlready == false else { continue }
      uniqueElements.append(value)
    }
    return uniqueElements
  }
}

extension Package.Dependency.Kind: Equatable {
  public static func == (
    lhs: PackageDescription.Package.Dependency.Kind,
    rhs: PackageDescription.Package.Dependency.Kind
  ) -> Bool {
    switch lhs {
    case .fileSystem(name: _, path: let lhsPath):
      switch rhs {
      case .fileSystem(name:_, let rhsPath):
        return lhsPath == rhsPath
      case .registry, .sourceControl:
        return false
      @unknown default:
        return false
      }
    case .registry(id: let lhsID, requirement: _):
      switch rhs {
      case .registry(id: let rhsID, requirement: _):
        return lhsID == rhsID
      case .fileSystem, .sourceControl:
        return false
      @unknown default:
        return false
      }
    case .sourceControl(name: _, location: let lhsLocation, requirement: _):
      switch rhs {
      case .sourceControl(name: _, location: let rhsLocation, requirement: _):
        return lhsLocation == rhsLocation
      case .fileSystem, .registry:
        return false
      @unknown default:
        return false
      }
    @unknown default:
      return false
    }
  }
}

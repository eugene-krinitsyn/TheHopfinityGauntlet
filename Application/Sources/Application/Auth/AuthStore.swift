import Foundation
import ShopifyAPI
import NetworkSession

@MainActor
final class AuthStore: ObservableObject, Sendable {

  @Published private(set) var showEmailEntry: Bool = false
  private var emailContinuation: CheckedContinuation<String, Never>?

  @Published private(set) var showCodeEntry: Bool = false
  private var codeContinuation: CheckedContinuation<String, Never>?

  private lazy var shopifyAPI: ShopifyAPI = {
    ShopifyAPI(
      configuration: .init(
        networkSession: .shared,
        basePath: "https://account.beerrepublic.eu",
        shopifyDomain: "firma-bier.myshopify.com",
        authEmailProvider: requestAuthEmail,
        confirmationCodeProvider: requestConfirmationCode
      )
    )
  }()
}

extension AuthStore {
  func onTapSendEmail(_ email: String) {
    let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
    emailContinuation?.resume(returning: email)
  }

  func onTapSendCode(_ code: String) {
    let code = code.trimmingCharacters(in: .whitespacesAndNewlines)
    codeContinuation?.resume(returning: code)
  }
}

private extension AuthStore {
  func requestAuthEmail() async throws -> String {
    return await withCheckedContinuation { [weak self] continuation in
      self?.emailContinuation = continuation
      self?.showEmailEntry = true
    }
  }

  func requestConfirmationCode() async throws -> String {
    return await withCheckedContinuation { [weak self] continuation in
      self?.codeContinuation = continuation
      self?.showCodeEntry = true
    }
  }
}

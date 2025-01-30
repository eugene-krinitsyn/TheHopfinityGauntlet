import SwiftUI

struct AuthView: View {
  @ObservedObject var store: AuthStore
  @State private var emailInput: String = ""
  @State private var codeInput: String = ""

  var body: some View {
    VStack {
      if store.showEmailEntry {
        TextField("Enter email", text: $emailInput)
        Button("Get code") {
          store.onTapSendEmail(emailInput)
        }
      }

      if store.showCodeEntry {
        TextField("Enter code", text: $codeInput)
        Button("Go") {
          store.onTapSendCode(codeInput)
        }
      }
    }
  }
}

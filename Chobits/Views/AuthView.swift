import AuthenticationServices
import SwiftData
import SwiftUI
import UIKit

struct AuthView: View {
  var slogan: String

  var body: some View {
    VStack {
      Text(slogan)
      Button {
        Task {
          await signInView.signIn()
        }
      } label: {
        Text("登录")
      }.adaptiveButtonStyle(.borderedProminent)
    }
  }

  private var signInView: SignInViewModel {
    return SignInViewModel()
  }
}

class SignInViewModel: NSObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }

  func handleAuthCallback(callback: URL?, error: Error?) {
    guard error == nil, let successURL = callback else {
      return
    }
    let query = URLComponents(string: successURL.absoluteString)?
      .queryItems?.filter { $0.name == "code" }.first
    let authorizationCode = query?.value ?? ""
    Task {
      if authorizationCode.isEmpty {
        Notifier.shared.alert(message: "failed to get oauth token")
      }
      do {
        try await Chii.shared.exchangeForAccessToken(code: authorizationCode)
      } catch {
        Notifier.shared.alert(message: "failed to exchange for access token: \(error)")
      }
    }
  }

  func signIn() async {
    let authURL = await Chii.shared.buildOAuthURL()
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "bangumi") {
      callback, error in
      self.handleAuthCallback(callback: callback, error: error)
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = false
    session.start()
  }
}

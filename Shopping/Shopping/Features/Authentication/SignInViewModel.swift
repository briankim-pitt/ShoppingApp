import Foundation
import Observation

@MainActor
@Observable
final class SignInViewModel {
    var mode: SignInMode = .signIn
    var email = ""
    var password = ""
    var isSubmitting = false
    var errorMessage: String?

    var canSubmit: Bool {
        !isSubmitting && email.contains("@") && password.count >= 6
    }

    func submit(using appModel: AppModel) async {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            switch mode {
            case .signIn:
                try await appModel.signIn(email: email, password: password)
            case .signUp:
                try await appModel.signUp(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

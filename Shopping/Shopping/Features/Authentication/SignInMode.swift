enum SignInMode: String, CaseIterable, Identifiable {
    case signIn
    case signUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .signIn: "Sign In"
        case .signUp: "Create Account"
        }
    }
}

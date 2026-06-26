struct UnavailableAuthService: AuthServing {
    func hasSession() async throws -> Bool { false }

    func signIn(email: String, password: String) async throws {
        throw ConfigurationError.missingSupabaseURL
    }

    func signUp(email: String, password: String) async throws {
        throw ConfigurationError.missingSupabaseURL
    }

    func signOut() async throws {}
}

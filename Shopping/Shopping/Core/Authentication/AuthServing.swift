protocol AuthServing: Sendable {
    func hasSession() async throws -> Bool
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() async throws
}

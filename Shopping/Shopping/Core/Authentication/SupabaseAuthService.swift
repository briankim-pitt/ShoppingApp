import Supabase

struct SupabaseAuthService: AuthServing {
    let client: SupabaseClient

    func hasSession() async throws -> Bool {
        _ = try await client.auth.session
        return true
    }

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }
}

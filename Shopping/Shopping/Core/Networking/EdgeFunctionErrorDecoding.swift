import Foundation
import Supabase

private struct EdgeFunctionErrorBody: Decodable {
    let error: String
}

/// Runs an Edge Function call and rethrows non-2xx responses as readable
/// errors, using the `{"error": "..."}` body our functions return.
func withReadableEdgeFunctionError<T: Sendable>(
    _ operation: () async throws -> T
) async throws -> T {
    do {
        return try await operation()
    } catch let FunctionsError.httpError(code, data) {
        if let body = try? JSONDecoder().decode(
            EdgeFunctionErrorBody.self,
            from: data
        ) {
            throw APIError.message(body.error)
        }

        throw APIError.message("The server returned status \(code).")
    }
}

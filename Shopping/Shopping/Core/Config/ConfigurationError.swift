import Foundation

enum ConfigurationError: LocalizedError {
    case missingSupabaseURL
    case missingPublishableKey
    case secretKeyNotAllowed

    var errorDescription: String? {
        switch self {
        case .missingSupabaseURL:
            "Set SUPABASE_URL in the target build settings."
        case .missingPublishableKey:
            "Set SUPABASE_PUBLISHABLE_KEY to a publishable or legacy anon key."
        case .secretKeyNotAllowed:
            "A Supabase secret key must never be embedded in the iOS app."
        }
    }
}

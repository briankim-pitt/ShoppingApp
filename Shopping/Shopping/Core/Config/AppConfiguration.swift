import Foundation

struct AppConfiguration: Sendable {
    let supabaseURL: URL
    let supabasePublishableKey: String

    init(bundle: Bundle = .main) throws {
        guard
            let rawURL = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: rawURL),
            !rawURL.isEmpty
        else {
            throw ConfigurationError.missingSupabaseURL
        }

        guard let key = bundle.object(
            forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY"
        ) as? String else {
            throw ConfigurationError.missingPublishableKey
        }

        if key.hasPrefix("sb_secret_") {
            throw ConfigurationError.secretKeyNotAllowed
        }

        guard key.hasPrefix("sb_publishable_") || key.hasPrefix("eyJ") else {
            throw ConfigurationError.missingPublishableKey
        }

        supabaseURL = url
        supabasePublishableKey = key
    }
}

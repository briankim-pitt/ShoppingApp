import Foundation

extension URL {
    static func productImportURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = validHTTPURL(from: trimmed) {
            return url
        }

        guard !trimmed.contains("://") else { return nil }

        if trimmed.hasPrefix("//") {
            return validHTTPURL(from: "https:\(trimmed)")
        }

        guard !trimmed.hasPrefix("/") else { return nil }
        return validHTTPURL(from: "https://\(trimmed)")
    }

    private static func validHTTPURL(from rawValue: String) -> URL? {
        guard let url = URL(string: rawValue),
              url.scheme == "http" || url.scheme == "https",
              url.host() != nil
        else {
            return nil
        }

        return url
    }
}

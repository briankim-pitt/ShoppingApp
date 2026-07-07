import Foundation

struct PendingProductImport: Equatable, Sendable {
    let url: URL
    let extracted: ExtractedProductMetadata?

    /// Parses a `shopping://import-product` deep link, including the optional
    /// metadata extracted in the browser by the Safari extension.
    init?(deepLink: URL) {
        guard deepLink.scheme == "shopping",
              deepLink.host() == "import-product",
              let components = URLComponents(
                  url: deepLink,
                  resolvingAgainstBaseURL: false
              )
        else {
            return nil
        }

        func value(_ name: String) -> String? {
            let raw = components.queryItems?
                .first { $0.name == name }?
                .value?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return raw?.isEmpty == false ? raw : nil
        }

        guard let rawProductURL = value("url"),
              let productURL = URL.productImportURL(from: rawProductURL)
        else {
            return nil
        }

        url = productURL
        extracted = value("title").map { title in
            ExtractedProductMetadata(
                title: title,
                description: value("description"),
                imageURL: value("image").flatMap(URL.productImportURL),
                priceAmount: value("price").flatMap {
                    Decimal(string: $0, locale: Locale(identifier: "en_US"))
                },
                currencyCode: value("currency")?.uppercased(),
                brand: value("brand")
            )
        }
    }
}

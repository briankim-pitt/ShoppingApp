import Foundation

protocol ProductImportServing: Sendable {
    func importProduct(
        from url: URL,
        extracted: ExtractedProductMetadata?
    ) async throws -> ProductImportResult
}

extension ProductImportServing {
    func importProduct(from url: URL) async throws -> ProductImportResult {
        try await importProduct(from: url, extracted: nil)
    }
}

import Foundation

struct UnavailableProductImportService: ProductImportServing {
    func importProduct(
        from url: URL,
        extracted: ExtractedProductMetadata?
    ) async throws -> ProductImportResult {
        throw APIError.message("Product imports are unavailable because the app is not configured.")
    }
}

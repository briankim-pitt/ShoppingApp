import Foundation

protocol ProductImportServing: Sendable {
    func importProduct(from url: URL) async throws -> ProductImportResult
}

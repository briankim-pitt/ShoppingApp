import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var mode: SearchMode = .products
    var productQuery = ""
    var products: [Product] = []
    var isSearchingProducts = false
    var hasSearchedProducts = false
    var correctedQuery: String?
    var productURL = ""
    var isImporting = false
    var result: ProductImportResult?
    var errorMessage: String?

    var canImport: Bool {
        URL(string: trimmedURL) != nil && !isImporting
    }

    var canSearchProducts: Bool {
        trimmedProductQuery.count >= 2 && !isSearchingProducts
    }

    private var trimmedProductQuery: String {
        productQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedURL: String {
        productURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func importProduct(using appModel: AppModel) async {
        guard let url = URL(string: trimmedURL), !isImporting else { return }

        isImporting = true
        errorMessage = nil
        defer { isImporting = false }

        do {
            result = try await appModel.importProduct(from: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchProducts(using appModel: AppModel) async {
        guard canSearchProducts else { return }

        isSearchingProducts = true
        hasSearchedProducts = true
        errorMessage = nil
        defer { isSearchingProducts = false }

        do {
            let response = try await appModel.searchProducts(
                query: trimmedProductQuery
            )
            products = response.products
            correctedQuery = response.correctedQuery
        } catch {
            products = []
            correctedQuery = nil
            errorMessage = error.localizedDescription
        }
    }
}

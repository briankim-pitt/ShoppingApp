import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var mode: SearchMode = .products
    var productQuery = ""
    var products: [Product] = []
    var brands: [ProductBrand] = []
    var isSearchingProducts = false
    var hasSearchedProducts = false
    var productURL = ""
    var isImporting = false
    var result: ProductImportResult?
    var errorMessage: String?
    private var hasLoadedInitialProducts = false

    var canImport: Bool {
        URL.productImportURL(from: trimmedURL) != nil && !isImporting
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
        guard let url = URL.productImportURL(from: trimmedURL),
              !isImporting else { return }
        await importProduct(from: url, using: appModel)
    }

    func importProduct(
        from url: URL,
        extracted: ExtractedProductMetadata? = nil,
        using appModel: AppModel
    ) async {
        guard !isImporting else { return }

        isImporting = true
        errorMessage = nil
        mode = .url
        productURL = url.absoluteString
        defer { isImporting = false }

        do {
            result = try await appModel.importProduct(
                from: url,
                extracted: extracted
            )
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
            products = try await appModel.searchProducts(
                query: trimmedProductQuery
            )
        } catch {
            products = []
            errorMessage = error.localizedDescription
        }
    }

    func loadInitialProducts(using appModel: AppModel) async {
        guard !hasLoadedInitialProducts else { return }

        hasLoadedInitialProducts = true
        await loadCatalog(using: appModel)
    }

    func resetToCatalog(using appModel: AppModel) async {
        productQuery = ""
        hasSearchedProducts = false
        await loadCatalog(using: appModel)
    }

    var popularProducts: [Product] {
        Array(products.prefix(6))
    }

    var recommendedProducts: [Product] {
        Array(products.dropFirst(6))
    }

    func removeProduct(id: UUID) {
        products.removeAll { $0.id == id }
    }

    private func loadCatalog(using appModel: AppModel) async {
        guard !isSearchingProducts else { return }

        isSearchingProducts = true
        errorMessage = nil
        defer { isSearchingProducts = false }

        async let loadedProducts = appModel.browseProducts()
        async let loadedBrands = loadBrands(using: appModel)

        do {
            products = try await loadedProducts
            brands = await loadedBrands
        } catch {
            products = []
            brands = []
            errorMessage = error.localizedDescription
        }
    }

    private func loadBrands(using appModel: AppModel) async -> [ProductBrand] {
        (try? await appModel.listBrands()) ?? []
    }
}

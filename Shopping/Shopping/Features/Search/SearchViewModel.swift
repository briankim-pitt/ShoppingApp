import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var mode: SearchMode = .products
    var selectedCategory: ProductSearchCategory = .all
    var productQuery = ""
    var products: [Product] = []
    var brands: [ProductBrand] = []
    var isSearchingProducts = false
    var hasSearchedProducts = false
    var correctedQuery: String?
    private var dominantCategoryID: String?
    var productURL = ""
    var isImporting = false
    var result: ProductImportResult?
    var errorMessage: String?
    private var hasLoadedInitialProducts = false

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

        await performProductSearch(
            query: trimmedProductQuery,
            using: appModel
        )
    }

    func searchProducts(
        in category: ProductSearchCategory,
        using appModel: AppModel
    ) async {
        guard !isSearchingProducts else { return }

        selectedCategory = category
        await performProductSearch(
            query: category.searchQuery,
            using: appModel
        )
    }

    func loadInitialProducts(using appModel: AppModel) async {
        guard !hasLoadedInitialProducts else { return }

        hasLoadedInitialProducts = true
        await searchProducts(in: .all, using: appModel)
    }

    var popularProducts: [Product] {
        Array(products.prefix(6))
    }

    var recommendedProducts: [Product] {
        Array(products.dropFirst(6))
    }

    private func performProductSearch(
        query: String,
        using appModel: AppModel
    ) async {
        isSearchingProducts = true
        hasSearchedProducts = true
        errorMessage = nil
        defer { isSearchingProducts = false }

        do {
            let response = try await appModel.searchProducts(
                query: query
            )
            products = response.products
            brands = response.brandRefinements
            dominantCategoryID = response.dominantCategoryID
            correctedQuery = response.correctedQuery
        } catch {
            products = []
            brands = []
            dominantCategoryID = nil
            correctedQuery = nil
            errorMessage = error.localizedDescription
        }
    }

    func brandSelection(for brand: ProductBrand) -> BrandSelection {
        BrandSelection(
            name: brand.name,
            categoryID: dominantCategoryID
        )
    }
}

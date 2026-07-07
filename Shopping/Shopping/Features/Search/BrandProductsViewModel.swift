import Foundation
import Observation

@MainActor
@Observable
final class BrandProductsViewModel {
    var products: [Product] = []
    var isLoading = true
    var errorMessage: String?

    private var hasLoaded = false

    func load(selection: BrandSelection, using appModel: AppModel) async {
        guard !hasLoaded else { return }

        hasLoaded = true
        await fetch(selection: selection, using: appModel)
    }

    func retry(selection: BrandSelection, using appModel: AppModel) async {
        await fetch(selection: selection, using: appModel)
    }

    private func fetch(
        selection: BrandSelection,
        using appModel: AppModel
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await appModel.searchProducts(
                query: selection.name,
                brand: selection.name,
                categoryID: selection.categoryID
            )
            products = response.products
        } catch {
            products = []
            errorMessage = error.localizedDescription
        }
    }
}

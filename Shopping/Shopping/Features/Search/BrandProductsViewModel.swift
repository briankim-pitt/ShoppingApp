import Foundation
import Observation

@MainActor
@Observable
final class BrandProductsViewModel {
    var products: [Product] = []
    var isLoading = true
    var errorMessage: String?

    private var hasLoaded = false

    func load(brand: ProductBrand, using appModel: AppModel) async {
        guard !hasLoaded else { return }

        hasLoaded = true
        await fetch(brand: brand, using: appModel)
    }

    func retry(brand: ProductBrand, using appModel: AppModel) async {
        await fetch(brand: brand, using: appModel)
    }

    func removeProduct(id: UUID) {
        products.removeAll { $0.id == id }
    }

    private func fetch(
        brand: ProductBrand,
        using appModel: AppModel
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            products = try await appModel.products(forBrand: brand.name)
        } catch {
            products = []
            errorMessage = error.localizedDescription
        }
    }
}

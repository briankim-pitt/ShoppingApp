import Foundation

struct UnavailableCatalogService: CatalogServing {
    func browseProducts() async throws -> [Product] {
        throw ConfigurationError.missingSupabaseURL
    }

    func searchProducts(query: String) async throws -> [Product] {
        throw ConfigurationError.missingSupabaseURL
    }

    func products(forBrand brand: String) async throws -> [Product] {
        throw ConfigurationError.missingSupabaseURL
    }

    func listBrands() async throws -> [ProductBrand] {
        throw ConfigurationError.missingSupabaseURL
    }

    func heroImage(forProductID productID: UUID) async throws -> URL? {
        throw ConfigurationError.missingSupabaseURL
    }
}

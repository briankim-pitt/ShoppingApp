protocol CatalogServing: Sendable {
    func browseProducts() async throws -> [Product]
    func searchProducts(query: String) async throws -> [Product]
    func products(forBrand brand: String) async throws -> [Product]
    func listBrands() async throws -> [ProductBrand]
}

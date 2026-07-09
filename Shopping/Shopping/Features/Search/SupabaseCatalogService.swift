import Foundation
import Supabase

struct SupabaseCatalogService: CatalogServing {
    private struct SearchProductsRequest: Encodable {
        let query: String
    }

    private struct SearchProductsResponse: Decodable {
        let products: [Product]
    }

    private struct HeroImageRequest: Encodable {
        let productID: UUID

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
        }
    }

    private struct HeroImageResponse: Decodable {
        let heroImageURL: URL?

        enum CodingKeys: String, CodingKey {
            case heroImageURL = "hero_image_url"
        }
    }

    private let productColumns = """
        id,
        canonical_url,
        source_domain,
        title,
        description,
        brand,
        image_url,
        currency_code,
        price_amount,
        wandercoin_price_amount,
        created_at,
        updated_at,
        last_imported_at
        """

    let client: SupabaseClient

    func browseProducts() async throws -> [Product] {
        try await client
            .from("products")
            .select(productColumns)
            .order("last_imported_at", ascending: false)
            .limit(50)
            .execute()
            .value
    }

    func searchProducts(query: String) async throws -> [Product] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let response: SearchProductsResponse = try await withReadableEdgeFunctionError {
            try await client.functions.invoke(
                "search-products",
                options: FunctionInvokeOptions(
                    body: SearchProductsRequest(query: trimmed)
                )
            )
        }

        return response.products
    }

    func products(forBrand brand: String) async throws -> [Product] {
        try await client
            .from("products")
            .select(productColumns)
            .ilike("brand", pattern: brand)
            .order("last_imported_at", ascending: false)
            .limit(50)
            .execute()
            .value
    }

    func heroImage(forProductID productID: UUID) async throws -> URL? {
        let response: HeroImageResponse = try await withReadableEdgeFunctionError {
            try await client.functions.invoke(
                "product-hero-image",
                options: FunctionInvokeOptions(
                    body: HeroImageRequest(productID: productID)
                )
            )
        }

        return response.heroImageURL
    }

    func listBrands() async throws -> [ProductBrand] {
        try await client
            .from("product_brands")
            .select()
            .order("match_count", ascending: false)
            .limit(20)
            .execute()
            .value
    }

}

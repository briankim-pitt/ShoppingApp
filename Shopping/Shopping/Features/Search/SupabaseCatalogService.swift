import Foundation
import Supabase

struct SupabaseCatalogService: CatalogServing {
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
        let sanitized = sanitizedSearchQuery(query)
        guard !sanitized.isEmpty else { return [] }

        return try await client
            .from("products")
            .select(productColumns)
            .or("title.ilike.%\(sanitized)%,brand.ilike.%\(sanitized)%")
            .order("last_imported_at", ascending: false)
            .limit(50)
            .execute()
            .value
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

    func listBrands() async throws -> [ProductBrand] {
        try await client
            .from("product_brands")
            .select()
            .order("match_count", ascending: false)
            .limit(20)
            .execute()
            .value
    }

    private func sanitizedSearchQuery(_ query: String) -> String {
        query
            .filter { !"%(),.".contains($0) }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

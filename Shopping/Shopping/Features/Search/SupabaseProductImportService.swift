import Foundation
import Supabase

struct SupabaseProductImportService: ProductImportServing {
    private struct ImportProductRequest: Encodable {
        let url: URL
    }

    let client: SupabaseClient

    func importProduct(from url: URL) async throws -> ProductImportResult {
        try await client.functions.invoke(
            "import-product",
            options: FunctionInvokeOptions(
                body: ImportProductRequest(url: url)
            )
        )
    }
}

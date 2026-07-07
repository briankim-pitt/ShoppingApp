import Foundation
import Supabase

struct SupabaseProductImportService: ProductImportServing {
    private struct ImportProductRequest: Encodable {
        let url: URL
        let extracted: ExtractedProductMetadata?
    }

    let client: SupabaseClient

    func importProduct(
        from url: URL,
        extracted: ExtractedProductMetadata?
    ) async throws -> ProductImportResult {
        try await withReadableEdgeFunctionError {
            try await client.functions.invoke(
                "import-product",
                options: FunctionInvokeOptions(
                    body: ImportProductRequest(
                        url: url,
                        extracted: extracted
                    )
                )
            )
        }
    }
}

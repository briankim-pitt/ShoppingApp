import Foundation
import Supabase

struct SupabaseProductImportService: ProductImportServing {
    private struct ImportProductRequest: Encodable {
        let url: URL
        let extracted: ExtractedProductMetadata?
    }

    private struct DeleteImportRequest: Encodable {
        let productID: UUID

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
        }
    }

    private struct DeleteImportResponse: Decodable {
        let deletedProduct: Bool

        enum CodingKeys: String, CodingKey {
            case deletedProduct = "deleted_product"
        }
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

    func deleteImport(forProductID productID: UUID) async throws {
        let _: DeleteImportResponse = try await withReadableEdgeFunctionError {
            try await client.functions.invoke(
                "delete-product-import",
                options: FunctionInvokeOptions(
                    body: DeleteImportRequest(productID: productID)
                )
            )
        }
    }
}

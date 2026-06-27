import Foundation

struct ProductImportResult: Decodable, Equatable, Sendable {
    let product: Product
    let importRecord: ProductImport

    enum CodingKeys: String, CodingKey {
        case product
        case importRecord = "import"
    }
}

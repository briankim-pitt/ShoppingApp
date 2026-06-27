import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var productURL = ""
    var isImporting = false
    var result: ProductImportResult?
    var errorMessage: String?

    var canImport: Bool {
        URL(string: trimmedURL) != nil && !isImporting
    }

    private var trimmedURL: String {
        productURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func importProduct(using appModel: AppModel) async {
        guard let url = URL(string: trimmedURL), !isImporting else { return }

        isImporting = true
        errorMessage = nil
        defer { isImporting = false }

        do {
            result = try await appModel.importProduct(from: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

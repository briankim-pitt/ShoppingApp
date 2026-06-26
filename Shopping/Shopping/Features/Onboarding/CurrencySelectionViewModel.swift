import Foundation
import Observation

@MainActor
@Observable
final class CurrencySelectionViewModel {
    var currencies: [SupportedCurrency] = []
    var selectedCode: String?
    var isLoading = false
    var isSaving = false
    var errorMessage: String?

    var canContinue: Bool {
        selectedCode != nil && !isSaving
    }

    func load(using appModel: AppModel) async {
        guard currencies.isEmpty, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currencies = try await appModel.listCurrencies()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(using appModel: AppModel) async {
        guard let selectedCode, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await appModel.selectHomeCurrency(selectedCode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

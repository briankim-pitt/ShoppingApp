import Observation
import Foundation

@MainActor
@Observable
final class OrdersViewModel {
    var orders: [VirtualOrder] = []
    var isLoading = true
    var errorMessage: String?

    @ObservationIgnored private var isRequestInFlight = false

    func observe(using appModel: AppModel) async {
        await load(using: appModel)

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(15))
            } catch {
                return
            }

            await load(
                using: appModel,
                showLoadingState: false,
                reportError: false
            )
        }
    }

    func refresh(using appModel: AppModel) async {
        await load(
            using: appModel,
            showLoadingState: false,
            reportError: true
        )
    }

    func retry(using appModel: AppModel) async {
        await load(using: appModel)
    }

    private func load(
        using appModel: AppModel,
        showLoadingState: Bool = true,
        reportError: Bool = true
    ) async {
        guard !isRequestInFlight else { return }

        isRequestInFlight = true
        if showLoadingState {
            isLoading = true
        }
        if reportError {
            errorMessage = nil
        }

        defer {
            isRequestInFlight = false
            isLoading = false
        }

        do {
            orders = try await appModel.listOrders()
            errorMessage = nil
        } catch {
            guard !Task.isCancelled else { return }
            if reportError {
                errorMessage = error.localizedDescription
            }
        }
    }
}

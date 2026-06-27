import SwiftUI

struct CurrencySelectionView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = CurrencySelectionViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.currencies) { currency in
                        Button {
                            viewModel.selectedCode = currency.currencyCode
                        } label: {
                            CurrencyRow(
                                currency: currency,
                                isSelected: viewModel.selectedCode == currency.currencyCode
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .appPageTitle("Home Currency")
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task {
                        await viewModel.save(using: appModel)
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canContinue)
                .padding()
                .background(.bar)
            }
            .task {
                await viewModel.load(using: appModel)
            }
        }
    }
}

#Preview {
    CurrencySelectionView()
        .environment(PreviewData.onboardingAppModel)
}

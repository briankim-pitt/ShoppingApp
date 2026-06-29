import SwiftUI

struct OrdersView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = OrdersViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color.brandPrimary)
                } else if let errorMessage = viewModel.errorMessage,
                          viewModel.orders.isEmpty {
                    ScrollView {
                        ContentUnavailableView {
                            BrandEmptyStateLabel(
                                title: "Couldn't Load Orders",
                                systemImage: "wifi.exclamationmark"
                            )
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button("Try Again", systemImage: "arrow.clockwise", action: retry)
                        }
                        .containerRelativeFrame(.vertical)
                    }
                    .scrollBounceBehavior(.always)
                    .brandPageBackground()
                    .refreshable {
                        await viewModel.refresh(using: appModel)
                    }
                } else if viewModel.orders.isEmpty {
                    ScrollView {
                        ContentUnavailableView {
                            BrandEmptyStateLabel(
                                title: "No Orders Yet",
                                systemImage: "shippingbox"
                            )
                        } description: {
                            Text("Your virtual purchases will appear here.")
                        }
                        .containerRelativeFrame(.vertical)
                    }
                    .scrollBounceBehavior(.always)
                    .brandPageBackground()
                    .refreshable {
                        await viewModel.refresh(using: appModel)
                    }
                } else {
                    List {
                        if let errorMessage = viewModel.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(Color.brandAccentCoral)
                                .brandListRow()
                        }

                        ForEach(viewModel.orders) { order in
                            NavigationLink {
                                OrderDetailView(
                                    orderID: order.id,
                                    viewModel: viewModel
                                )
                            } label: {
                                OrderRow(order: order)
                            }
                            .brandListRow()
                        }
                    }
                    .brandPageBackground()
                    .refreshable {
                        await viewModel.refresh(using: appModel)
                    }
                }
            }
            .appPageTitle("Orders")
            .task {
                await viewModel.observe(using: appModel)
            }
        }
    }

    private func retry() {
        Task {
            await viewModel.retry(using: appModel)
        }
    }
}

#Preview {
    OrdersView()
        .environment(PreviewData.readyAppModel)
}

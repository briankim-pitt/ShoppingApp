import SwiftUI

struct OrdersView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = OrdersViewModel()
    @State private var selectedFilter = OrderListFilter.all

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    Picker("Order filter", selection: $selectedFilter) {
                        ForEach(OrderListFilter.allCases) { filter in
                            Text(filter.title)
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.brandPrimary)

                    if viewModel.isLoading && viewModel.orders.isEmpty {
                        ProgressView()
                            .controlSize(.large)
                            .tint(Color.brandPrimary)
                            .containerRelativeFrame(.vertical)
                    } else if let errorMessage = viewModel.errorMessage,
                              viewModel.orders.isEmpty {
                        ContentUnavailableView {
                            BrandEmptyStateLabel(
                                title: "Couldn't Load Orders",
                                systemImage: "wifi.exclamationmark"
                            )
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button(
                                "Try Again",
                                systemImage: "arrow.clockwise",
                                action: retry
                            )
                            .buttonStyle(.glassProminent)
                            .tint(Color.brandPrimary)
                        }
                        .containerRelativeFrame(.vertical)
                    } else if viewModel.orders.isEmpty {
                        ContentUnavailableView {
                            BrandEmptyStateLabel(
                                title: "No Orders Yet",
                                systemImage: "shippingbox"
                            )
                        } description: {
                            Text("Your virtual purchases will appear here.")
                        }
                        .containerRelativeFrame(.vertical)
                    } else if filteredOrders.isEmpty {
                        ContentUnavailableView {
                            BrandEmptyStateLabel(
                                title: "No Past Orders",
                                systemImage: "clock"
                            )
                        } description: {
                            Text("Completed and cancelled orders will appear here.")
                        }
                        .containerRelativeFrame(.vertical)
                    } else {
                        if let errorMessage = viewModel.errorMessage {
                            Label(
                                errorMessage,
                                systemImage: "exclamationmark.triangle"
                            )
                            .foregroundStyle(Color.brandAccentCoral)
                        }

                        ForEach(filteredOrders) { order in
                            NavigationLink {
                                OrderDetailView(
                                    orderID: order.id,
                                    viewModel: viewModel
                                )
                            } label: {
                                OrderRow(order: order)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .scrollBounceBehavior(.always)
            .brandPageBackground()
            .refreshable {
                await viewModel.refresh(using: appModel)
            }
            .appPageTitle("Orders")
            .task {
                await viewModel.observe(using: appModel)
            }
        }
    }

    private var filteredOrders: [VirtualOrder] {
        viewModel.orders.filter {
            selectedFilter.includes($0.status)
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

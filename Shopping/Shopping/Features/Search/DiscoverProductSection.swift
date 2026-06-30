import SwiftUI

struct DiscoverProductSection: View {
    let title: LocalizedStringKey
    let products: [Product]
    let collapsedCount: Int
    @Binding var showsAll: Bool
    let cart: CartStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if products.count > collapsedCount {
                    Button(
                        showsAll ? "Show less" : "See all",
                        action: toggleExpanded
                    )
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(Color.brandPrimary)
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 20
            ) {
                ForEach(visibleProducts) { product in
                    DiscoverProductCard(
                        product: product,
                        isInCart: cart.contains(productID: product.id),
                        addToCart: {
                            cart.add(product)
                        }
                    )
                }
            }
        }
    }

    private var visibleProducts: ArraySlice<Product> {
        products.prefix(showsAll ? products.count : collapsedCount)
    }

    private func toggleExpanded() {
        showsAll.toggle()
    }
}

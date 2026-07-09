import SwiftUI

struct DiscoverProductSection: View {
    let title: LocalizedStringKey
    let products: [Product]
    let transitionNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 20
            ) {
                ForEach(products) { product in
                    NavigationLink(value: product) {
                        DiscoverProductCard(
                            product: product,
                            transitionNamespace: transitionNamespace
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

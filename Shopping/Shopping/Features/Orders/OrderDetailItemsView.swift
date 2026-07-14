import SwiftUI

struct OrderDetailItemsView: View {
    let order: VirtualOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.headline)

            ForEach(order.items) { item in
                OrderItemRow(item: item)
                    .orderItemCardStyle()
            }
        }
    }
}

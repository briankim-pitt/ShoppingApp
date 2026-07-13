import SwiftUI

struct OrderDetailItemsView: View {
    let order: VirtualOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.title2.bold())

            ForEach(order.items) { item in
                OrderItemRow(item: item)
                    .padding(12)
                    .background(Color.brandPurpleSurface, in: .rect(cornerRadius: 16))
            }
        }
    }
}

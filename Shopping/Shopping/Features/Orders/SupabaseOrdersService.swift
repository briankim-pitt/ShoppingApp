import Supabase

struct SupabaseOrdersService: OrdersServing {
    let client: SupabaseClient

    func listOrders() async throws -> [VirtualOrder] {
        try await client
            .from("virtual_orders")
            .select(
                """
                id,
                status,
                total_amount,
                currency_code,
                placed_at,
                processing_at,
                shipped_at,
                out_for_delivery_at,
                delivered_at,
                cancelled_at,
                estimated_delivery_at,
                next_status_at,
                origin_name,
                origin_latitude,
                origin_longitude,
                destination_name,
                destination_latitude,
                destination_longitude,
                created_at,
                virtual_order_items (
                  id,
                  product_id,
                  title_snapshot,
                  image_url_snapshot,
                  currency_code,
                  unit_price_amount,
                  source_currency_code,
                  source_price_amount,
                  quantity,
                  created_at
                ),
                virtual_order_status_events (
                  id,
                  status,
                  occurred_at
                )
                """
            )
            .order("created_at", ascending: false)
            .order(
                "occurred_at",
                ascending: true,
                referencedTable: "virtual_order_status_events"
            )
            .limit(50)
            .execute()
            .value
    }
}

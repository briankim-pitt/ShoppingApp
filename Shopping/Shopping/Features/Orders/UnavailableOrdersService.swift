struct UnavailableOrdersService: OrdersServing {
    func listOrders() async throws -> [VirtualOrder] {
        throw ConfigurationError.missingSupabaseURL
    }
}

protocol OrdersServing: Sendable {
    func listOrders() async throws -> [VirtualOrder]
}

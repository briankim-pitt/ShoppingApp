import Supabase

struct SupabaseWalletService: WalletServing {
    let client: SupabaseClient

    func getWallet() async throws -> VirtualWallet {
        try await client
            .rpc("get_my_wallet")
            .execute()
            .value
    }
}

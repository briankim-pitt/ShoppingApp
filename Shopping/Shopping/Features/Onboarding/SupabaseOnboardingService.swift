import Foundation
import Supabase

struct SupabaseOnboardingService: OnboardingServing {
    private struct SetCurrencyRequest: Encodable {
        let currencyCode: String

        enum CodingKeys: String, CodingKey {
            case currencyCode = "currency_code"
        }
    }

    private struct SetCurrencyResponse: Decodable {
        let balance: Money
        let homeCurrency: HomeCurrency

        struct HomeCurrency: Decodable {
            let selectedAt: Date

            enum CodingKeys: String, CodingKey {
                case selectedAt = "selected_at"
            }
        }

        enum CodingKeys: String, CodingKey {
            case balance
            case homeCurrency = "home_currency"
        }

        var wallet: VirtualWallet {
            VirtualWallet(
                balance: balance,
                homeCurrencySelected: true,
                homeCurrencySelectedAt: homeCurrency.selectedAt
            )
        }
    }

    let client: SupabaseClient

    func listCurrencies() async throws -> [SupportedCurrency] {
        try await client
            .from("supported_currencies")
            .select("currency_code,display_name,symbol,minor_unit")
            .order("sort_order")
            .execute()
            .value
    }

    func setHomeCurrency(_ currencyCode: String) async throws -> VirtualWallet {
        let response: SetCurrencyResponse = try await client.functions.invoke(
            "set-home-currency",
            options: FunctionInvokeOptions(
                body: SetCurrencyRequest(currencyCode: currencyCode)
            )
        )
        return response.wallet
    }
}

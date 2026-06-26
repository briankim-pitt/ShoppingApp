import Foundation
import Testing
@testable import Shopping

struct MoneyTests {
    @Test
    func decodesSnakeCaseCurrencyCode() throws {
        let data = Data(#"{"amount":1000,"currency_code":"JPY"}"#.utf8)
        let money = try JSONDecoder.supabase.decode(Money.self, from: data)

        #expect(money.amount == 1000)
        #expect(money.currencyCode == "JPY")
    }
}

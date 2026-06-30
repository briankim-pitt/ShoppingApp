import Foundation
import Testing
@testable import Shopping

struct URLHTTPSUpgradeTests {
    @Test
    func upgradesHTTPImageURLToHTTPS() throws {
        let url = try #require(
            URL(string: "http://i.ebayimg.sandbox.ebay.com/images/item.jpg")
        )

        #expect(
            url.upgradingToHTTPS.absoluteString
                == "https://i.ebayimg.sandbox.ebay.com/images/item.jpg"
        )
    }

    @Test
    func preservesExistingHTTPSURL() throws {
        let url = try #require(
            URL(string: "https://i.ebayimg.com/images/item.jpg")
        )

        #expect(url.upgradingToHTTPS == url)
    }
}

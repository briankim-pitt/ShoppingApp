import Testing
@testable import Shopping

struct OrderListFilterTests {
    @Test
    func allIncludesEveryStatus() {
        for status in VirtualOrderStatus.allCases {
            #expect(OrderListFilter.all.includes(status))
        }
    }

    @Test
    func pastIncludesOnlyTerminalStatuses() {
        #expect(OrderListFilter.past.includes(.delivered))
        #expect(OrderListFilter.past.includes(.cancelled))
        #expect(!OrderListFilter.past.includes(.shipped))
    }
}

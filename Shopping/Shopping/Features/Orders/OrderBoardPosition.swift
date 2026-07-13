import CoreGraphics
import Foundation

struct OrderBoardPosition: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat

    func clamped() -> OrderBoardPosition {
        OrderBoardPosition(
            x: min(max(x, 0), 1),
            y: min(max(y, 0), 1)
        )
    }

    static func initial(
        for id: UUID,
        at index: Int,
        itemCount: Int
    ) -> OrderBoardPosition {
        let column = index % 3
        let row = index / 3
        let rowCount = max(Int(ceil(Double(itemCount) / 3)), 1)
        let itemsInRow = min(3, itemCount - row * 3)
        let horizontalBase = baseX(column: column, itemsInRow: itemsInRow)
        let horizontalJitter = (unitValue(for: id, salt: 17) - 0.5) * 0.18
        let verticalBase = rowCount == 1 ? 0.18 : CGFloat(row) / CGFloat(rowCount - 1)
        let verticalJitter = (unitValue(for: id, salt: 43) - 0.5) * 0.1

        return OrderBoardPosition(
            x: horizontalBase + horizontalJitter,
            y: verticalBase + verticalJitter
        ).clamped()
    }

    private static func baseX(column: Int, itemsInRow: Int) -> CGFloat {
        switch itemsInRow {
        case 1:
            0.5
        case 2:
            column == 0 ? 0.2 : 0.8
        default:
            [0.05, 0.5, 0.95][column]
        }
    }

    private static func unitValue(for id: UUID, salt: UInt64) -> CGFloat {
        var state = id.uuidString.utf8.reduce(salt) { partialResult, byte in
            (partialResult &* 16_777_619) ^ UInt64(byte)
        }
        state ^= state >> 13
        state &*= 1_099_511_628_211
        return CGFloat(state % 10_000) / 9_999
    }
}

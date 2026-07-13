import Foundation
import CoreGraphics

struct OrderBoardItem: Identifiable, Equatable {
    let order: VirtualOrder
    let item: VirtualOrderItem

    var id: UUID {
        item.id
    }

    var boardTileSize: CGFloat {
        102 + CGFloat(scatterSeed % 19)
    }

    var boardTileRotation: Double {
        Double(Int(scatterSeed % 7) - 3)
    }

    private var scatterSeed: UInt64 {
        id.uuidString.utf8.reduce(2_166_136_261) { partialResult, byte in
            (partialResult &* 16_777_619) ^ UInt64(byte)
        }
    }
}

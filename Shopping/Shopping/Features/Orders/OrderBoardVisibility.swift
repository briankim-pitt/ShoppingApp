import Foundation

struct OrderBoardVisibility: Codable, Equatable {
    var hiddenItemIDs: Set<UUID> = []
    var removedItemIDs: Set<UUID> = []
}

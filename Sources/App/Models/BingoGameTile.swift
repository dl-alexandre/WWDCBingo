import Fluent
import Vapor

final class BingoGameStateTile: Model {
    static let schema = "bingogamestate+tile"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "bingogamestate_id")
    var bingoGameState: BingoGameState
    
    @Parent(key: "tile_id")
    var tile: Tile
    
    @Field(key: "order")
    var order: Int
    
    init() { }
    
    init(order: Int) {
        self.order = order
    }
}


import Fluent
import Vapor

final class TileRight: Model {
    static let schema = "tile_right"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "tile_id")
    var tile: Tile
    
    @Parent(key: "tile_right")
    var tileRight: Tile
    
    init() { }
}

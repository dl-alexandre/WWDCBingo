import Fluent
import Vapor

final class GameBoardModel: Content, Model {
    static let schema = "gameboard"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "gameboard")
    var tiles: [UInt16 : Tile]
    
    @Parent(key: "gamestate")
    var bingoGame: BingoGameState
    
    init() { }
}

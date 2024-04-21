import Fluent
import Vapor

struct BingoGameDTO: Content {
    let id: UUID?
    let status: Status
    let tiles: [[Tile]]
    let user: User.IDValue?
}

final class BingoGameState: Model, Content {
    static let schema = "game"
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "status")
    var status: Status
    
    @Field(key: "tiles")
    var tiles: [Tile]
    
    @Parent(key: "user_id")
    var user: User
    
    init() { }
    
    init(game: BingoGame, user: User) throws {
        self.$user.id = try user.requireID()
        self.status = game.status
        self.tiles = game.flatTiles()
    }
}

extension BingoGameState: Equatable {
    static func == (lhs: BingoGameState, rhs: BingoGameState) -> Bool {
        lhs.id == rhs.id
        && lhs.status == rhs.status
        && lhs.tiles == rhs.tiles
        && lhs.$user.id == rhs.$user.id
    }
}

extension BingoGameState {
    var dto: BingoGameDTO {
        let tiles2D: [[Tile]] = BingoGame.makeBoard(from: tiles)
        
        return BingoGameDTO(id: self.id,
                     status: self.status,
                            tiles: tiles2D,
                            user: self.$user.id)
    }
}

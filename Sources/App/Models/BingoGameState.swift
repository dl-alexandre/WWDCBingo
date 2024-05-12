import Fluent
import Vapor

struct BingoGameDTO: Content, Codable {
    let id: UUID?
    let status: Status
    let tiles: [Tile]
    let user: User.IDValue?
}

final class BingoGameState: Model, Content, Codable {
    static let schema = "game"
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "status")
    var status: Status
    
    @Siblings(through: BingoGameStateTile.self,
              from: \.$bingoGameState,
              to: \.$tile)
    var tiles: [Tile]
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "permissions")
    var permissions: Permission
    
    init() { }
    
    init(game: BingoGame, user: User, db: any Database) async throws {
        self.$user.id = try user.requireID()
        self.status = game.status
        self.permissions = .userPublic
        try await self.save(on: db)
        
        let enumeratedTiles = game.flatTiles().enumerated()
        for tile in enumeratedTiles {
            try await self.$tiles.attach(tile.element, on: db) { pivot in
                pivot.order = tile.offset
            }
        }
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
    
    public func getOrderedTilesFor(gameID: BingoGameState.IDValue, db: any Database) async throws -> [Tile] {
        let bingoTiles = try await BingoGameStateTile.query(on: db)
            .filter(\BingoGameStateTile.$bingoGameState.$id == gameID)
            .sort(\BingoGameStateTile.$order)
            .with(\.$tile)
            .all()
            .map { $0.tile }
        return bingoTiles
    }
    
    func makeDTO(on db: any Database) async throws -> BingoGameDTO {
        guard let id else { throw Abort(.badRequest) }
        let orderedTiles = try await getOrderedTilesFor(gameID: id, db: db)
        
        return BingoGameDTO(id: self.id,
                            status: self.status,
                            tiles: orderedTiles,
                            user: self.$user.id)
    }
    
    func updateTile(_ newTile: Tile) {
        for var oldTile in self.tiles {
            guard oldTile.id == newTile.id else { continue }
            oldTile = newTile
        }
    }
}

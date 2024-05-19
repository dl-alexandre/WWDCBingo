import Fluent
import Vapor

extension BingoGame {
    static func hydrate(on db: Database) async throws {
        guard let admin = try await User.query(on: db)
            .filter(\.$email == ServerConfig.adminUserPublic.email!)
            .first() else {
            fatalError("Cannot hydrate: no admin user")
        }
        let tiles = try await Tile.query(on: db).all()
        guard let gooodMorningTile = tiles.first(where: { tile in
            tile.title == "Good Morning!"
        }) else {
            fatalError("Couldn’t get center tile")
        }
        let game = try await BingoGame(tiles: tiles, 
                                       size: 5,
                                       centerTile: gooodMorningTile)
            .gameState(for: admin, on: db)
        try await game.save(on: db)
    }
}

import Fluent
import Vapor

struct TileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tiles = routes.grouped("tiles")

        tiles.get(use: { try await self.index(req: $0) })
        
        let tilesProtected = tiles.grouped(SessionToken.asyncAuthenticator(), SessionToken.guardMiddleware())
        tilesProtected.post(use: { try await self.create(req: $0) })
        tilesProtected.group(":tileID") { tile in
            tile.put(use: { try await self.update(req: $0 )})
            tile.delete(use: { try await self.delete(req: $0) })
        }
    }
    
    // MARK: CRUD
    func index(req: Request) async throws -> [Tile] {
        try await Tile.query(on: req.db).all()
    }

    func create(req: Request) async throws -> Tile {
        var tilePublic = try req.content.decode(TilePublic.self)
        tilePublic.isPlayed = false
        let tile = try await tilePublic.makeTile(on: req)
        try await tile.save(on: req.db)
        return tile
    }
    
    func update(req: Request) async throws -> Tile {
        let tilePublic = try req.content.decode(TilePublic.self)
        async let newTile = tilePublic.makeTile(on: req)
        async let tile =  Tile.find(req.parameters.get("tileID"),
                                    on: req.db)
        guard let tile = try await tile,
              let tileID = tile.id,
              let updatedTile = try? await newTile,
              let newTileID = updatedTile.id,
              tileID == newTileID else {
            throw Abort(.notFound)
        }
        
        let user = try await newTile.$user.get(on: req.db)
        let requestUserIsAdmin = try await user.isAdmin(db: req.db)
        
        guard tile.$user.id == newTileID || requestUserIsAdmin else {
            throw Abort(.unauthorized)
        }
        
        tile.title = updatedTile.title
        if requestUserIsAdmin {
            tile.isPlayed = updatedTile.isPlayed
        }
        try await tile.save(on: req.db)
        return tile
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let tile = try await Tile.find(req.parameters.get("tileID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await tile.delete(on: req.db)
        return .noContent
    }
}

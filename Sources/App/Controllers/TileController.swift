import Fluent
import Vapor

struct TileController: RouteCollection {
    struct QueryParams: Content {
        var query: String?
        var permission: Permission?
    }
    
    func boot(routes: RoutesBuilder) throws {
        let tiles = routes.grouped("tiles")

        tiles.get(use: { try await self.index(req: $0) })
        
        let tilesProtected = tiles.grouped(SessionToken.asyncAuthenticator(), SessionToken.guardMiddleware())
        tilesProtected.post(use: { try await self.create(req: $0) })
        tilesProtected.post("search") { try await self.search(req: $0) }
        tilesProtected.post("locktiles") { try await self.adminChangePermissions(req: $0) }
        tilesProtected.group("admin") { adminTile in
            adminTile.get("") { try await self.adminView(req: $0) }
        }
        tilesProtected.group(":tileID") { tile in
            tile.put(use: { try await self.update(req: $0 )})
            tile.put("view") { try await self.updateView(req: $0) }
        }
        
        let tilesSessionProtected = tiles.grouped(User.sessionAuthenticator(), User.redirectMiddleware(path: "/"))
        tilesSessionProtected.post(use: { try await self.createAdmin(req: $0) })
        tilesSessionProtected.get("admin") { try await self.adminView(req: $0) }
        tilesSessionProtected.get("view") { try await self.adminView(req: $0) }
        tilesSessionProtected.group(":tileID") { adminTileID in
            adminTileID.put("view") { try await self.updateView(req: $0) }
            adminTileID.delete(use: { try await self.delete(req: $0) })
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
    
    func createAdmin(req: Request) async throws -> String {
        _ = try await create(req: req)
        let tiles = try await index(req: req)
        return ListTileView(tiles: tiles).render()
    }
    
    func adminChangePermissions(req: Request) async throws -> HTTPStatus {
        async let adminUser = req.adminUser()
        guard let query = try? req.query.decode(QueryParams.self),
              let permission = query.permission else {
            throw Abort(.badRequest, reason: "need valid permission")
        }
        async let allTiles = Tile.query(on: req.db).all()
        guard let _ = try? await adminUser else {
            return .unauthorized
        }
        tileLoop: for tile in try await allTiles {
            guard tile.permissions != .userPrivate else {
                continue tileLoop
            }
            tile.permissions = permission
            try await tile.save(on: req.db)
        }
        return .ok
    }
    
    func updateWebsocketClients(req: Request, tileID: Tile.IDValue) async throws {
        guard let connectedClients = await req.application.connectedClients?.clients else {
            // Nobody on websockets, just return
            return
        }
        
        let games = try await BingoGameStateTile.query(on: req.db)
            .filter(\BingoGameStateTile.$tile.$id == tileID)
            .with(\.$bingoGameState)
            .all()
            .map {
                $0.bingoGameState
            }
        
        for game in games {
            let gameDTO = try await game.makeDTO(on: req.db)
            let gameView = GameView(game: gameDTO).render()
            
            connectedClients.forEach { _, webSocket in
                webSocket.send(gameView)
            }
        }
    }
    
    func update(req: Request) async throws -> Tile {
        let tilePublic = try req.content.decode(TilePublic.self)
        async let newTile = tilePublic.makeTile(on: req)
        async let tile = Tile.find(req.parameters.get("tileID"),
                                    on: req.db)
        guard let tile = try await tile,
              let tileID = tile.id,
              let updatedTile = try? await newTile,
              let newTileID = updatedTile.id,
              tileID == newTileID else {
            req.logger.warning("Could not update tile", metadata: [
                "tile" : .init(stringLiteral: req.parameters.get("tileID") ?? "no tile id")
            ])
            throw Abort(.notFound)
        }
        
        let user = try await newTile.$user.get(on: req.db)
        let requestUserIsAdmin = try await user.isAdmin(db: req.db)
        
        guard tile.$user.id == newTileID || requestUserIsAdmin else {
            throw Abort(.unauthorized)
        }
        
        if !requestUserIsAdmin {
            switch tile.permissions {
            case .adminPrivate:
                throw Abort(.unauthorized, reason: "Tile is banned")
            case .adminPublic:
                throw Abort(.unauthorized, reason: "Sysadmin owns this tile")
            case .viewOnly:
                throw Abort(.unauthorized, reason: "Tile is view-only. Are we live?")
            default:
                break
            }
        } else { 
            // only admins can say a title has been played
            tile.isPlayed = updatedTile.isPlayed
        }
        
        tile.title = updatedTile.title
        
        try await tile.save(on: req.db) // Done udpating tile
        
        do {
            try await updateWebsocketClients(req: req, tileID: tileID)
            return tile
        } catch {
            throw Abort(.internalServerError, reason: error.localizedDescription)
        }
    }

    func delete(req: Request) async throws -> String {
        guard let tile = try await Tile.find(req.parameters.get("tileID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await tile.$bingoGames.detachAll(on: req.db)
        try await tile.delete(on: req.db)
        return ""
    }
    
    func search(req: Request) async throws -> Page<Tile> {
        let searchQuery = try req.query.decode(QueryParams.self)
        guard let query = searchQuery.query,
              query.count > 1 else {
            throw Abort(.badRequest, reason: "Need a query of at least 2 characters")
        }
        let tiles = try await Tile.query(on: req.db)
            .filter(\Tile.$title ~~ query)
            .paginate(for: req)
        return tiles
    }
}

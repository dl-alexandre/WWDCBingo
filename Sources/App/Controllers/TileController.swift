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
        tilesProtected.group("admin") { adminTile in
            adminTile.post("locktiles") { try await self.adminChangePermissions(req: $0) }
        }
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
        
        if !requestUserIsAdmin {
            switch tile.permissions {
            case .adminPrivate:
                throw Abort(.unauthorized, reason: "Tile is banned")
            case .adminPublic:
                throw Abort(.unauthorized, reason: "Sysadmin owns this tile")
            case .userPrivate:
                break
            case .userPublic:
                break
            case .viewOnly:
                throw Abort(.unauthorized, reason: "Tile is view-only. Are we live?")
            }
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
    
    func search(req: Request) async throws -> Page<Tile> {
        let searchQuery = try req.query.decode(QueryParams.self)
        guard let query = searchQuery.query,
              query.count > 1 else {
            throw Abort(.badRequest, reason: "Need a query of at least 2 characters")
        }
        let tiles = try await Tile.query(on: req.db)
            .filter(\Tile.$title =~ query)
            .paginate(for: req)
        return tiles
    }
}

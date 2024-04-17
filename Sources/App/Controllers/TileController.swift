import Fluent
import Vapor

struct TileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tiles = routes.grouped("tiles")

        tiles.get(use: { try await self.index(req: $0) })
        tiles.post(use: { try await self.create(req: $0) })
        tiles.group(":tileID") { todo in
            tiles.delete(use: { try await self.delete(req: $0) })
        }
    }
    
    func index(req: Request) async throws -> [Tile] {
        try await Tile.query(on: req.db).all()
    }

    func create(req: Request) async throws -> Tile {
        let tile = try req.content.decode(Tile.self)

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

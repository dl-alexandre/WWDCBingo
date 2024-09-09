import Fluent
import Vapor

extension TileController {
    func adminView(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        guard try await user.isAdmin(db: req.db) else {
            throw Abort(.unauthorized)
        }
        let allTiles = try await Tile.query(on: req.db).with(\.$user).all()
        let adminTileView = AdminTileView(tiles: allTiles)
        let webView = WebView.body(adminTileView, user: user)
        return WebView.response(for: webView)
    }
    
    func updateView(req: Request) async throws -> Response {
        let tile = try await update(req: req)
        try await tile.$user.load(on: req.db)
        guard let tileID = try? tile.requireID() else {
            throw Abort(.badRequest)
        }
        let goodMorning: Tile? = try await Tile.query(on: req.db)
            .filter(\Tile.$title, .equal, "Good Morning!").first()
        guard try goodMorning?.requireID() != tileID else {
            throw Abort(.badRequest, reason: "The central “Good Morning!” tile.")
        }
        return WebView.response(for: EditTileRow(tile: tile, tileID: tileID.uuidString))
    }

}

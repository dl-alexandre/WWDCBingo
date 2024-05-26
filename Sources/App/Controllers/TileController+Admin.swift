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
}

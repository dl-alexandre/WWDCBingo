import Fluent
import Vapor

extension TileController {
    func adminView(req: Request) async throws -> String {
        let userID = req.session.authenticated(User.self)
        guard let user = try await User.find(userID, on: req.db),
              try await user.isAdmin(db: req.db) else {
            throw Abort(.unauthorized)
        }
        let allTiles = try await Tile.query(on: req.db).all()
        let adminTileView = AdminTileView(tiles: allTiles).render()
        return adminTileView
    }
}

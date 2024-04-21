import Fluent

struct CreateInitialTiles: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await Tile.hydrate(on: database)
    }
    
    func revert(on database: any Database) async throws {
        database.logger.warning("!! Initial tiles do not get reverted !!")
    }
}

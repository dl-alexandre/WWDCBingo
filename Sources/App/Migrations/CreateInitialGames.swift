import Fluent

struct CreateInitialGames: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await BingoGame.hydrate(on: database)
    }
    
    func revert(on database: any Database) async throws {
        database.logger.error("!! Initial games do not get reverted !!")
    }
}

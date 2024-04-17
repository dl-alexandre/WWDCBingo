import Fluent

struct CreateTile: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Tile.schema)
            .id()
            .field("title", .string, .required)
            .field("played", .bool, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Tile.schema).delete()
    }
}

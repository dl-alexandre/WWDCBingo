import Fluent

struct CreateBingoGameStateTile: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(BingoGameStateTile.schema)
            .id()
            .unique(on: "id")
            .field("bingogamestate_id", .uuid, .required, .references(BingoGameState.schema, "id"))
            .field("tile_id", .uuid, .required, .references(Tile.schema, "id"))
            .field("order", .int, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(BingoGameStateTile.schema).delete()
    }
}

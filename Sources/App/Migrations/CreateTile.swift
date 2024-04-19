import Fluent

struct CreateTile: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Tile.schema)
            .id()
            .field("title", .string, .required)
            .unique(on: "title")
            .field("played", .bool, .required)
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Tile.schema).delete()
    }
}

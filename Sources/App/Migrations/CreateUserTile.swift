import Fluent

struct CreateUserTile: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UserTile.schema)
            .id()
            .unique(on: "id")
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .field("tile_id", .uuid, .required, .references(Tile.schema, "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(UserTile.schema) .delete()
    }
}

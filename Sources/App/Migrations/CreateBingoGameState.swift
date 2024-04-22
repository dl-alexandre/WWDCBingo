import Fluent

struct CreateBingoGameState: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(BingoGameState.schema)
            .id()
            .unique(on: "id")
            .field("status", .int, .required)
            .field("tiles", .array(of: .json))
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .field("permissions", .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(BingoGameState.schema).delete()
    }
}

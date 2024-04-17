import Fluent

struct CreateTag: AsyncMigration {
    func prepare(on database: any FluentKit.Database) async throws {
        try await database.schema(Tag.schema)
            .id()
            .field("name", .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Tag.schema).delete()
    }
}

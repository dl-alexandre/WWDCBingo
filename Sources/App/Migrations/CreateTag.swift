import Fluent

struct CreateTag: AsyncMigration {
    func prepare(on database: any FluentKit.Database) async throws {
        try await database.schema(Tag.schema)
            .id()
            .unique(on: "id")
            .field("name", .string, .required)
            .unique(on: "name")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Tag.schema).delete()
    }
}

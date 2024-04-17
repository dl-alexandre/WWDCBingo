import Fluent

struct CreateUserTag: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UserTag.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .field("tag_id", .uuid, .required, .references(Tag.schema, "id"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(UserTag.schema).delete()
    }
}

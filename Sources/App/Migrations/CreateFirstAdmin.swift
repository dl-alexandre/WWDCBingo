import Fluent

struct CreateFirstAdmin: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await Configuration.adminTag.save(on: database)
        guard let adminTag: Tag = try await Tag.query(on: database)
            .filter(\.$name, .equal, Configuration.adminTagName)
            .first() else {
            fatalError("Could not create Admin tag")
        }
        
        let pubUser = Configuration.adminUserPublic
        guard let adminUser = User(userPublic: pubUser) else {
            fatalError("Could not migrate admin")
        }
        try await adminUser.save(on: database)
        try await adminUser.$tags.attach(adminTag, on: database)
        let adminID = try adminUser.requireID()
        database.logger.critical("Admin created")
    }

    func revert(on database: Database) async throws {
        database.logger.critical("!! ADMIN DB REVERT DOES NOT EXIST !! Admin user must be manually removed from db")
    }
}

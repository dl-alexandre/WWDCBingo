import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: try Configuration.postgresConfiguration()
    ), as: .psql)

    app.migrations.add(CreateTodo())
    app.migrations.add(CreateTag())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserTag())
    app.migrations.add(CreateFirstAdmin())
    
    app.views.use(.leaf)

    // register routes
    try routes(app)
}

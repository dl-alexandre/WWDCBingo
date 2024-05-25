import JWT
import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // Also serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Database
    app.databases.use(DatabaseConfigurationFactory
        .postgres(configuration: try ServerConfig.postgresConfiguration()), 
                      as: .psql)
    
    // JWT
    guard let signerKey = ServerConfig.jwtSignerKey else {
        throw Errors.misconfigured(reason: "BINGO_JWT_SIGNER_KEY not set in Environment")
    }
    app.jwt.signers.use(.hs512(key: signerKey))
    
    // Use cookies
    app.sessions.use(.fluent)
    // Cookies for Login
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(User.sessionAuthenticator())

    // Migrations
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateTag())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserTag())
    app.migrations.add(CreateFirstAdmin())
    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateTile())
    app.migrations.add(CreateBingoGameState())
    app.migrations.add(CreateBingoGameStateTile())
    app.migrations.add(CreateInitialTiles())
    app.migrations.add(CreateInitialGames())
    
    app.views.use(.leaf)

    // register routes
    try routes(app)
}

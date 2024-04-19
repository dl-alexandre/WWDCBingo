import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("healthcheck") { req async throws -> String in
        let userCount = try await User.query(on: req.db).count()
        let routeCount = req.application.routes.all.count
        return "OK \(userCount) \(routeCount)"
    }
    
    let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
    passwordProtected.post("login") { req -> [String: String] in
        let user = try req.auth.require(User.self)
        let payload = try SessionToken(user: user)
//        let token = try req.application.jwt.signers.sign(payload)
        return try [ "jwt" : req.jwt.sign(payload) ]
    }
    
    let secure = app.grouped(SessionToken.authenticator(), SessionToken.guardMiddleware())
    secure.get("jwt") { req -> String in
        let sessToken = try req.jwt.verify(as: SessionToken.self)
        return "\(sessToken.subject) \(sessToken.expiration) \(sessToken.userID)"
    }

    try app.register(collection: TodoController())
    try app.register(collection: UserController())
    try app.register(collection: TileController())
}

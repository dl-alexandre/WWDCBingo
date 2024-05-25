import Leaf
import Fluent
import Vapor

extension Application {
    var connectedClients: WebSocketClients? {
        get {
            self.storage[WebSocketClientsKey.self]
        }
        set {
            self.storage[WebSocketClientsKey.self] = newValue
        }
    }
}

func storeConnection(id: String, req: Request, ws: WebSocket) async throws {
    if let connectedClients = req.application.connectedClients {
        await connectedClients.add(id: id, ws: ws)
    } else {
        req.application.connectedClients = .init()
        await req.application.connectedClients?.add(id: id, ws: ws)
    }
}

func routes(_ app: Application) throws {
    struct HomeContent: Encodable {
        var title: String
        var gameData: BingoGameDTO
    }
    
    app.get { req async throws in
        print(req.hasSession)
        let user = try? req.auth.require(User.self)
        return Response(status: .ok,
                        body: Response.Body(stringLiteral: WebView.homePage(user)))
    }

    app.get("healthcheck") { req async throws -> String in
        let userCount = try await User.query(on: req.db).count()
        let routeCount = req.application.routes.all.count
        let connectedClients = await app.connectedClients?.clients
            .keys.enumerated()
            .map { clientKeyValue in
                String(clientKeyValue.offset) + "\t " + clientKeyValue.element.description
            }
            .joined(separator: "\n")
        return "OK \(userCount) \(routeCount)\n\(connectedClients ?? "—")"
    }
    
    // MARK: JWT Login
    let passwordProtected = app.grouped(User.authenticator(), User.guardMiddleware())
    passwordProtected.post("login") { req -> [String: String] in
        let user = try req.auth.require(User.self)
        let payload = try SessionToken(user: user)
        return try [ "jwt" : req.jwt.sign(payload) ]
    }
    
    let secure = app.grouped(User.sessionAuthenticator(), SessionToken.guardMiddleware())
    secure.get("jwt") { req -> String in
        let sessToken = try req.jwt.verify(as: SessionToken.self)
        return "\(sessToken.subject) \(sessToken.expiration) \(sessToken.userID)"
    }
    
    secure.webSocket("mygames") { req, ws in
        guard let user = try? await req.registeredUser() else {
            req.logger.error("Could not get user id")
            try? await ws.close()
            return
        }
        do {
            try await storeConnection(id: req.id, req: req, ws: ws)
        } catch {
            req.logger.error("\(error.localizedDescription)")
            try? await ws.close()
        }
        do {
            let games = try await user.$bingoGames.get(on: req.db)
            for game in games {
                let gameDTO = try await game.makeDTO(on: req.db)
                let gameView = GameView(game: gameDTO).render()
                try await ws.send(gameView)
            }
        } catch {
            try? await ws.send("Could not send games")
        }
    }

    try app.register(collection: TodoController())
    try app.register(collection: UserController())
    try app.register(collection: TileController())
    try app.register(collection: GameController())
    try app.register(collection: CustomizeController())
}

import Fluent
import Plot
import Vapor

struct GameController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let games = routes.grouped("games")
        
        games.get(use: { try await self.index(req: $0) }) 
        games.post(use: { try await self.create(req: $0) })
        games.get("view") { try await self.gameView(req: $0) }
        
        games.group(":gameID") { game in
            game.get(use: { try await self.get(req: $0) })
            let frameSize = 15 * 1024 // 15KiB
            game.webSocket("play", maxFrameSize: WebSocketMaxFrameSize(integerLiteral: frameSize)) { req, ws in
                ws.onPing { ws, buffy in
                    ws.send("ping")
                }
                ws.onText { ws, text in
                    if let uuid = UUID(uuidString: text) {
                        guard let game = try? await BingoGameState.find(uuid, on: req.db),
                              let gameDTOData = try? JSONEncoder().encode(game) else {
                            try? await ws.send("Not found")
                            return ()
                        }
                        ws.send(gameDTOData)
                    }
                    try? await ws.send(text.reversed())
                }
                ws.onBinary { ws, buffy in
                    let size = buffy.readableBytes
                    ws.send("Got \(size) bytes")
                }
                ws.onPong { ws, buffy in
                    ws.send("pong")
                }
                ws.onClose.whenComplete { _ in
                    print("closed")
                }
            }
        }
    }
    
    func gameView(req: Request) async throws -> String {
        let game = try await BingoGameState.query(on: req.db)
            .first()
        guard let game else {
            throw Abort(.notFound)
        }
        let gameDTO = try await game.makeDTO(on: req.db)
        return GameView(game: gameDTO).render()
    }
    
    // FIXME: This is brittle and hacky
    func index(req: Request) async throws -> Page<BingoGameState> {
        return try await BingoGameState.query(on: req.db).paginate(for: req)
    }
    
    func create(req: Request) async throws -> BingoGameState {
        async let user = req.registeredUser()
        async let goodMorning: Tile? = Tile.query(on: req.db)
            .filter(\Tile.$title, .equal, "Good Morning!").first()
        async let tiles = Tile.query(on: req.db)
            .filter(\.$title, .contains(inverse: true, .anywhere), "Good Morning!")
            .limit(25)
            .all()
        guard let goodMorning = try await goodMorning else {
            throw Abort(.internalServerError, reason: "Not a good morning")
        }
        let game = try BingoGame(tiles: try await tiles, 
                                 size: 5,
                                 centerTile: goodMorning)
        let gameState = try await game.gameState(for: try await user,
                                                 on: req.db)
        try await gameState.save(on: req.db)
        try await gameState.$tiles.load(on: req.db)
        return gameState
    }
    
    func get(req: Request) async throws -> some Content {
        guard let bingoGame = try await BingoGameState.find(req.parameters.get("gameID"), on: req.db),
              let bingoGameId = try? bingoGame.requireID() else {
            throw Abort(.notFound)
        }
        let bingoTiles = try await BingoGameStateTile.query(on: req.db)
            .filter(\BingoGameStateTile.$bingoGameState.$id == bingoGameId)
            .sort(\BingoGameStateTile.$order)
            .with(\.$tile)
            .all()
            .map { $0.tile }
        return BingoGameDTO(id: nil, status: bingoGame.status, tiles: bingoTiles, user: bingoGame.$user.id)
    }
}

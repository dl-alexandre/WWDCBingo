import Fluent
import Vapor

struct GameController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let games = routes.grouped("games")
        
        games.get(use: { try await self.index(req: $0) })
        games.post(use: { try await self.create(req: $0) })
        
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
    
    func index(req: Request) async throws -> Page<BingoGameDTO> {
        let thisGamePage = try await BingoGameState.query(on: req.db).paginate(for: req)
        let theseGameStateDTO = thisGamePage.map { $0.dto }
        return theseGameStateDTO
    }
    
    func create(req: Request) async throws -> BingoGameDTO {
        async let user = req.registeredUser()
        async let goodMorning: Tile? = Tile.query(on: req.db)
            .filter(\Tile.$title, .equal, "Good Morning!").first()
        async let tiles = Tile.query(on: req.db)
            .limit(25)
            .all()
        guard let goodMorning = try await goodMorning else {
            throw Abort(.internalServerError, reason: "Not a good morning")
        }
        let game = try BingoGame(tiles: try await tiles, size: 5, centerTile: goodMorning)
        let gameState = try game.gameState(for: try await user)
        try await gameState.save(on: req.db)
        return gameState.dto
    }
    
    func get(req: Request) async throws -> BingoGameDTO {
        guard let bingoGame = try await BingoGameState.find(req.parameters.get("gameID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return bingoGame.dto
    }
}

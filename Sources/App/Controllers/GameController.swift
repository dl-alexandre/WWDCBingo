import Fluent
import Plot
import Vapor

struct GameController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let games = routes.grouped("games")
        
        games.get(use: { try await self.index(req: $0) })
        games.post(use: { try await self.create(req: $0) })
        games.get("view") { try await self.gameView(req: $0) }
        games.get("random") { try await self.random(req: $0) }
        games.get("view", "random") {
            let randomGame = try await self.random(req: $0)
            return try await gameView(req: $0, for: randomGame)
        }
        
        games.group(":gameID") { game in
            game.get(use: { try await self.get(req: $0) })
            
            let frameSize = 15 * 1024 // 15KiB
            game.webSocket("play", maxFrameSize: WebSocketMaxFrameSize(integerLiteral: frameSize)) { req, ws in
                if req.application.connectedClients == nil {
                    req.application.connectedClients = WebSocketClients()
                }
                await req.application.connectedClients?.add(id: req.id, ws: ws)
                
                ws.onClose.whenComplete { _ in
                    Task {
                        await req.application.connectedClients?.remove(id: req.id)
                    }
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
        return try await gameView(req: req, for: game)
    }
    
    func gameView(req: Request, for game: BingoGameState) async throws -> String {
        let gameDTO = try await game.makeDTO(on: req.db)
        return GameView(game: gameDTO).render()
    }
    
    func index(req: Request) async throws -> Page<BingoGameState> {
        return try await BingoGameState.query(on: req.db).paginate(for: req)
    }
    
    func random(req: Request) async throws -> BingoGameState {
        let all = try await BingoGameState.query(on: req.db).all()
        guard let randomGame = all.shuffled().first else {
            throw Abort(.notFound, reason: "No games in database")
        }
        return randomGame
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

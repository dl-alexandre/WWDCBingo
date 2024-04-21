import Fluent
import Vapor

struct GameController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let games = routes.grouped("games")
        
        games.get(use: { try await self.index(req: $0) })
        games.post(use: { try await self.create(req: $0) })
        
        games.group(":gameID") { game in
            game.get(use: { try await self.get(req: $0) })
        }
    }
    
    func index(req: Request) async throws -> Page<BingoGameDTO> {
        let thisGamePage = try await BingoGameState.query(on: req.db).paginate(for: req)
        let theseGameStateDTO = thisGamePage.map { $0.dto }
        return theseGameStateDTO
    }
    
    func create(req: Request) async throws -> BingoGameDTO {
        async let user = req.registeredUser()
        async let tiles = Tile.query(on: req.db)
            .limit(25)
            .all()
        // and "good morning"
        let game = try BingoGame(tiles: try await tiles, size: 5)
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

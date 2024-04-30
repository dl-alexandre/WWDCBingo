import Fluent
import Foundation

extension BingoGame {
    func gameState(for user: User, on db: any Database) async throws -> BingoGameState {
        return try await BingoGameState(game: self, user: user, db: db)
    }
}

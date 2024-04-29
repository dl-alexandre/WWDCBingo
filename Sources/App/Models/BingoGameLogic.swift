import Fluent
import Foundation

struct BingoGame: Codable {
    enum Errors: Error {
        case invalid(reason: String)
    }
    
    var id: UUID
    var status: Status
    var tiles: [[Tile]]
    var permissions: Permission
    
    init(id: UUID? = nil, tiles: [Tile], size: Int, centerTile: Tile) throws {
        self.id = id ?? UUID()
        self.permissions = .userPublic
        let requiredBoardTileCount = size * size
        let terminalIndex = size - 1
        var randoTiles = tiles.shuffled()
        guard size > 0,
              tiles.count >= requiredBoardTileCount else {
            print("misconfigured")
            throw Errors.invalid(reason: "Must have the proper number of Tiles for board size squared")
        }
        let middleIndex = size.middle() - 1 // zero indexed
        var newBoard = [[Tile]]()
        rowLoop: for row in 0...terminalIndex {
            var newRow = [Tile]()
            columnLoop: for column in 0...terminalIndex {
                if row == middleIndex
                    && column == middleIndex {
                    newRow.append(centerTile)
                    continue columnLoop
                }
                guard let thisTile = randoTiles.popLast() else {
                    print("couldn't tile")
                    throw Errors.invalid(reason: "Failed to assign tiles")
                }
                newRow.append(thisTile)
            }
            newBoard.append(newRow)
        }
        self.tiles = newBoard
        self.status = .ready
        #if DEBUG
        print(self)
        #endif
    }
}

// MARK: Helpers
extension BingoGame: CustomStringConvertible {
    var description: String {
        var gameDescription = ""
        for row in tiles {
            var rowDescription = ""
            for tile in row {
                rowDescription += tile.isPlayed ? "√" : "x"
                rowDescription += "\t"
            }
            gameDescription.append(rowDescription + "\n")
        }
        return gameDescription
    }
    
    func flatTiles() -> [Tile] {
        tiles.flatMap { $0 }
    }
    
    static func makeBoard(from tiles: [Tile]) throws -> [[Tile]] {
        guard !tiles.isEmpty else {
            throw Errors.invalid(reason: "board my have some tiles")
        }
        let gameSize = Int(Double(tiles.count).squareRoot())
        let tiles2D = tiles.chunks(ofCount: gameSize).map { Array($0) }
        return tiles2D
    }
    /**
     func gameState(for user: User, on db: any Database) async throws -> BingoGameState {
         let gameState = try await BingoGameState(game: self, user: user, db: db)
         if gameState.hasChanges {
             try await gameState.save(on: db)
         }
 //        let flatty = self.flatTiles()
 //        try await gameState.$tiles.attach(flatty, on: db)
         return gameState
     }
     */
    func gameState(for user: User, on db: any Database) async throws -> BingoGameState {
        return try await BingoGameState(game: self, user: user, db: db)
    }
}

// MARK: Logic
extension BingoGame {
    
    @discardableResult
    public mutating func play(tile playedTile: Tile) throws -> Status {
        switch status {
        case .error:
            throw Errors.invalid(reason: "Game is in error state")
        case .winner:
            throw Errors.invalid(reason: "Already won!")
        default:
            break
        }
        status = .playing
        
        do {
            for row in tiles {
                for tile in row {
                    if try tile.requireID() == playedTile.id {
                        tile.isPlayed = true
                    }
                }
            }
        } catch {
            status = .error
        }
        
        if checkForWin() {
            status = .winner
        }
        
        return self.status
    }
    
    public func checkForWin() -> Bool {
        return hasRowWin() || hasColumnWin() || hasDiagonalWin()
    }
    
    private func hasRowWin() -> Bool {
        let rowCount = tiles.count
        
        for row in tiles {
            let winners = row.filter { $0.isPlayed }
            if winners.count == rowCount {
                print("Row win: \n\(self)")
                return true
            }
        }
        return false
    }
    
    private func hasColumnWin() -> Bool {
        let columnCount = tiles.count
        for currentColumn in 0..<columnCount {
            for currentRow in 0..<columnCount {
                if !tiles[currentRow][currentColumn].isPlayed {
                    break
                }
                if currentRow == columnCount - 1 {
                    print("Column Win: \n\(currentRow)\n\(self)")
                    return true
                }
            }
        }
        return false
    }
    
    private func hasDiagonalWin() -> Bool {
        let size = tiles.count
        var hasMainDiagonalWin = true
        var hasAntiDiagonalWin = true
        
        for dd in 0..<size {
            guard hasMainDiagonalWin || hasAntiDiagonalWin else {
                return false
            }
            // Check main diagonal (top-left to bottom-right)
            if !tiles[dd][dd].isPlayed {
                hasMainDiagonalWin = false
            }
            // Check anti-diagonal (top-right to bottom-left)
            if !tiles[dd][size - 1 - dd].isPlayed {
                hasAntiDiagonalWin = false
            }
        }
        
        // If either diagonal is winning, return true
        print("Diagonal Win \(hasMainDiagonalWin ? "main" : "anti")\n\(self)")
        return hasMainDiagonalWin || hasAntiDiagonalWin
    }
}

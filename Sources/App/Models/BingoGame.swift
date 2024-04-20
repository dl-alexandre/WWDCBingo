struct BingoGame: Codable {
    enum Errors: Error {
        case invalid(reason: String)
    }
    var tiles: [[Tile]]
    
    init(tiles: [Tile], size: Int) throws {
        let requiredBoardTileCount = size * size
        let terminalIndex = size - 1
        var randoTiles = tiles.shuffled()
        guard size > 0,
              tiles.count >= requiredBoardTileCount else {
            print("misconfigured")
            throw Errors.invalid(reason: "Must have exactly the proper number of Tiles for board size squared")
        }
        var newBoard = [[Tile]]()
        for _ in 0...terminalIndex {
            var newRow = [Tile]()
            for _ in 0...terminalIndex {
                guard let thisTile = randoTiles.popLast() else {
                    print("couldn't tile")
                    throw Errors.invalid(reason: "Failed to assign tiles")
                }
                newRow.append(thisTile)
            }
            newBoard.append(newRow)
        }
        self.tiles = newBoard
    }
}

// MARK: Helpers
extension BingoGame: CustomStringConvertible {
    var description: String {
        var gameDescription = ""
        for row in tiles {
            var rowDescription = ""
            for tile in row {
                rowDescription += tile.title
                rowDescription += "\t"
            }
            gameDescription.append(rowDescription + "\n")
        }
        return gameDescription
    }
}

// MARK: Logic
extension BingoGame {
    public func checkForWin() -> Bool {
        return hasRowWin() || hasColumnWin() || hasDiagonalWin()
    }
    
    private func hasRowWin() -> Bool {
        let rowCount = tiles.count
        
        for row in tiles {
            let winners = row.filter { $0.isPlayed }
            if winners.count == rowCount {
                return true
            }
        }
        return false
    }
    
    private func hasColumnWin() -> Bool {
        let columnCount = tiles.count
        for currentColumn in 0..<columnCount {
            for currentRow in 0..<columnCount {
                if !tiles[currentColumn][currentRow].isPlayed {
                    break
                }
                return true
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
        return hasMainDiagonalWin || hasAntiDiagonalWin
    }
}

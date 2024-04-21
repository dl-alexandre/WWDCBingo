@testable import App
import XCTVapor

final class GameTests: XCTestCase {
    private func createGame(size: Int = 5) throws -> (User, BingoGame, [Tile]) {
        let user = User(id: UUID(), givenName: "BI", familyName: "NGO", email: "bingo@example.com", password: "hola mundo")
        var someTiles = [Tile]()
        for ii in 1...25 {
            someTiles.append(try Tile(id: UUID(), title: String(ii), user: user))
        }
        let game = try BingoGame(tiles: someTiles, size: size)
        return (user, game, someTiles)
    }
    
    func testBingoGame() async throws {
        var (user, game, someTiles) = try createGame()
        
        XCTAssertNotNil(game)
        XCTAssertEqual(game.status, .ready)
        
        // Shall we play a game?
        let unknownTile = try Tile(id: UUID(), title: "This tile is not in the game’s tiles", isPlayed: true, user: user)
        XCTAssertNoThrow(try game.play(tile: unknownTile))
        XCTAssertEqual(game.status, .playing)
        
        // Let’s play some known tiles
        for index in 0..<24 {
            print("pass \(index)")
            someTiles = someTiles.shuffled()
            let currentState = try game.play(tile: someTiles.popLast()!)
            if index < 5 {
                XCTAssertEqual(currentState, .playing)
            }
            if currentState == .winner {
                print("Winner! (pass \(index))")
                XCTAssertGreaterThanOrEqual(index, 5)
                break
            }
            XCTAssertNotEqual(currentState, .error)
        }
        
        // Trying to play more tiles won’t update the game
        XCTAssertThrowsError(try game.play(tile: unknownTile))
        XCTAssertEqual(game.status, .winner)
        XCTAssertNotNil(game)
    }
    
    func testTiles() throws {
        let (_, game, _) = try createGame()
        
        let flatTiles = game.flatTiles()
        let tiles2D = BingoGame.makeBoard(from: flatTiles)
        XCTAssertEqual(game.tiles, tiles2D)
    }
    
    func testGameState() throws {
        let (user, game, _) = try createGame()
        XCTAssertNoThrow({
            let gameState = try game.gameState(for: user)
            let bingoState = try BingoGameState(game: game, user: user)
            XCTAssertNotNil(gameState)
            XCTAssertNotNil(bingoState)
            XCTAssertEqual(gameState, bingoState)
        })
    }
    
    func testInitFail() {
        XCTAssertThrowsError( try self.createGame(size: 0) )
        XCTAssertThrowsError( try self.createGame(size: -2) )
    }
}

/** Busted in Xcode
// MARK: Perf
extension GameTests {
    func testCreatePerformance() {
        measure {
            do {
                let _ = try createGame()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testPlayPerformance() throws {
        measure {
            do {
                var (_, game, tiles) = try createGame()
                for _ in 0..<5 {
                    tiles = tiles.shuffled()
                    let _ = try! game.play(tile: tiles.popLast()!)
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
}
*/

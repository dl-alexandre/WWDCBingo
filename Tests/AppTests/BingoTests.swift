@testable import App
import XCTVapor

final class GameTests: XCTestCase {
    var user: User!
    var middleTile: Tile!
    
    override func setUp() {
        let user = User(id: UUID(), givenName: "BI", familyName: "NGO", email: "bingo@example.com", password: "hola mundo")
        self.user = user
        self.middleTile = try! Tile(id: UUID(), title: "CENTER", isPlayed: true, user: user)
    }
    
    private func createGame(size: Int = 5, tileCount: Int = 25) throws -> (BingoGame, [Tile]) {
        var someTiles = [Tile]()
        for ii in 1...tileCount {
            someTiles.append(try Tile(id: UUID(), title: String(ii), user: user))
        }
        let game = try BingoGame(tiles: someTiles, size: size, centerTile: middleTile)
        return (game, someTiles)
    }
    
    func testBingoGame() async throws {
        var (game, someTiles) = try createGame()
        
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
    
    func testIntMiddle() {
        let number = 15
        let numberMiddle = number.middle()
        XCTAssertEqual(numberMiddle, 8)
    }
    
    func testTiles() throws {
        let (game, _) = try createGame()
        
        /// ``BingoGame`` can product a 1D array of tiles for serialization
        let flatTiles = game.flatTiles()
        
        /// The center tile of a ``BingoGame`` is dedetermanistic
        let middleIndex = flatTiles.count.middle() - 1
        let gameCenterTile = flatTiles[middleIndex] // zero indexed
        XCTAssertEqual(gameCenterTile, middleTile)
        
        /// ``BingoGame`` has a helper to create a 2D array representing the game board
        let tiles2D = BingoGame.makeBoard(from: flatTiles)
        XCTAssertEqual(game.tiles, tiles2D)
    }
    
    func testGameState() throws {
        let (game, _) = try createGame()
        XCTAssertNoThrow({
            let gameState = try game.gameState(for: self.user)
            let bingoState = try BingoGameState(game: game, user: self.user)
            XCTAssertNotNil(gameState)
            XCTAssertNotNil(bingoState)
            XCTAssertEqual(gameState, bingoState)
        })
    }
    
    func testInitFail() {
        // Must have a positive size
        XCTAssertThrowsError( try self.createGame(size: 0) )
        XCTAssertThrowsError( try self.createGame(size: -2) )
        
        // Must create enough Tiles
        XCTAssertThrowsError( try self.createGame(size: 100, tileCount: 99) )
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

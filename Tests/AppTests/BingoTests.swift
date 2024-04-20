@testable import App
import XCTVapor

final class GameTests: XCTestCase {
    private func createGame() -> (User, BingoGame, [Tile]) {
        let user = User(id: UUID(), givenName: "BI", familyName: "NGO", email: "bingo@example.com", password: "hola mundo")
        var someTiles = [Tile]()
        for ii in 1...25 {
            someTiles.append(try! Tile(id: UUID(), title: String(ii), user: user))
        }
        let game = try! BingoGame(tiles: someTiles, size: 5)
        return (user, game, someTiles)
    }
    
    func testBingoGame() async throws {
        var (user, game, someTiles) = createGame()
        
        XCTAssertNotNil(game)
        XCTAssertEqual(game.status, .ready)
        
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
        
        XCTAssertThrowsError(try game.play(tile: Tile(id: UUID(), title: "FAIL", isPlayed: true, user: user)))
        
        XCTAssertNotNil(game)
    }
}

// MARK: Perf
extension GameTests {
    func testCreatePerformance() {
        self.measure {
            var _ = createGame()
        }
    }
    
    func testPlayPerformance() {
        self.measure {
            var (_, game, tiles) = createGame()
            for _ in 0..<5 {
                tiles = tiles.shuffled()
                let _ = try! game.play(tile: tiles.popLast()!)
            }
        }
    }
}

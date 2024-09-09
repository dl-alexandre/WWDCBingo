import Plot

struct GameView: Component {
    let game: BingoGameDTO
    var body: Component {
        Div {
            for tile in game.tiles {
                Div(tile.title)
                    .class("tile \(tile.isPlayed ? "played" : "unplayed")")
            }
        }
        .class("game")
        .id("bingo-" + gameID())
        .attribute(named: "hx-ext", value: "ws")
        .attribute(named: "ws-connect", value: "/games/\(gameID())/play")
    }
}

extension GameView {
    func gameID() -> String {
        game.id?.uuidString ?? String(game.tiles.hashValue)
    }
}

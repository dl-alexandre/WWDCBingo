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
    }
}

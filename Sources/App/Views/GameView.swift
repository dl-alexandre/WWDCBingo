import Plot

struct GameView: Component {
    let game: BingoGameDTO
    var body: Component {
        Div {
            for tileRow in game.tiles {
//                Div {
                    for tile in tileRow {
                        Div(tile.title)
                            .class("tile \(tile.isPlayed ? "played" : "unplayed")")
                    }
//                }
            }
        }
        .class("game")
    }
}

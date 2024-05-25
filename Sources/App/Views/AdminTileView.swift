import Plot

struct AdminTileView: Component {
    let tiles: [Tile]
    var body: Component {
        Div {
            Text("Admin: Tiles")
            for tile in tiles {
                Div {
                    Text(tile.title)
                    Input(type: .checkbox)
                        .attribute(.checked( tile.isPlayed ))
                }
            }
        }
    }
}

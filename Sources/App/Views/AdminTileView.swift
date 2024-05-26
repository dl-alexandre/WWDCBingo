import Plot

struct AdminTileView: Component {
    let tiles: [Tile]
    var body: Component {
        Div {
            H1("Edit Tiles")
            for tile in tiles {
                if let tileID = try? tile.requireID() {
                    EditTileRow(tile: tile, tileID: tileID.uuidString)
                } else {
                    Div {
                        Text("Invalid: \(tile.title)")
                    }
                }
            }
        }
        .class("main")
    }
}

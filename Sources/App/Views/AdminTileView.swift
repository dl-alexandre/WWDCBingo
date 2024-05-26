import Plot

struct AdminTileView: Component {
    let tiles: [Tile]
    var body: Component {
        Div {
            Text("Admin: Tiles")
            for tile in tiles {
                if let tileID = try? tile.requireID() {
                    AdminTileRowView(tile: tile, tileID: tileID.uuidString)
                } else {
                    Div {
                        Text("Invalid: \(tile.title)")
                    }
                }
            }
        }
    }
}

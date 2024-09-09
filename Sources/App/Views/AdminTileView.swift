import Plot

struct CreateTileView: Component {
    var body: Component {
        Form(url: "") {
            Div {
                Label("Title") {
                    Input(type: .text, name: "title", isRequired: true)
                }
                Input(type: .hidden, name: "isPlayed", value: "false")
                Input(type: .submit)
            }
        }
        .id("tile-create")
        .attribute(named: "hx-post", value: "/tiles")
        .attribute(named: "hx-include", value: "this")
        .attribute(named: "hx-trigger", value: "submit")
        .attribute(named: "hx-target", value: "#tile-list")
    }
}

struct ListTileView: Component {
    let tiles: [Tile]
    var body: Component {
        Div {
            H1("Edit Tiles")
            List {
                for tile in tiles {
                    if let tileID = try? tile.requireID() {
                        ListItem {
                            EditTileRow(tile: tile, tileID: tileID.uuidString)
                        }
                    } else {
                        Div {
                            Text("Invalid: \(tile.title)")
                        }
                    }
                }
            }
            .listStyle(.ordered)
        }
        .id("tile-list")
    }
}

struct AdminTileView: Component {
    let tiles: [Tile]
    var body: Component {
        Div {
            H2 {
                Text("New Tile")
            }
            CreateTileView()
            ListTileView(tiles: tiles)
        }
        .class("main")
    }
}

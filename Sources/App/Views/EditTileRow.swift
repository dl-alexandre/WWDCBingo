import Plot

struct EditTileRow: Component {
    let tile: Tile
    let tileID: String
    
    var body: any Component {
        Div {
            Span {
                Label("") {
                    Span {
                        Input(type: .checkbox, name: "isPlayed")
                            .attribute(.checked( tile.isPlayed ))
                            .class("isPlayed")
                        Input(type: .text,
                              name: "title",
                              value: tile.title,
                              isRequired: true)
                        .class("title")
                    }
                    Span {
                        Input(type: .hidden,
                              name: "id",
                              value: tileID,
                              isRequired: true)
                        .class("tileID")
                        Input(type: .hidden,
                              name: "userID",
                              value: tile.$user.id.uuidString)
                    }
                }
            }
            .attribute(named: "hx-put", value: "/tiles/\(tileID)/view")
            .attribute(named: "hx-include", value: "this")
            .attribute(named: "hx-trigger", value: "change")
            Button {
                Text("Delete")
            }
            .attribute(named: "hx-delete", value: "/tiles/\(tileID)")
            .attribute(named: "hx-target", value: "#tile-\(tileID)")
            .attribute(named: "hx-swap", value: "innerHTML")
        }
        .class("edit-tile-row")
        .id("tile-\(tileID)")
    }
}

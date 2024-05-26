import Plot

struct EditTileRow: Component {
    let tile: Tile
    let tileID: String
    
    var body: any Component {
        Div {
            Label("") {
                Div {
                    Input(type: .checkbox, name: "isPlayed")
                        .attribute(.checked( tile.isPlayed ))
                        .class("isPlayed")
                    Input(type: .text,
                          name: "title",
                          value: tile.title,
                          isRequired: true)
                        .class("title")
                }
                Div {
                    Input(type: .hidden,
                          name: "id",
                          value: tileID,
                          isRequired: true)
                        .class("tileID")
                    Input(type: .hidden,
                          name: "userID",
                          value: try? tile.user.requireID().uuidString)
                }
            }
        }
        .class("edit-tile-row")
        .attribute(named: "hx-put", value: "/tiles/\(tileID)/view")
        .attribute(named: "hx-include", value: "this")
        .attribute(named: "hx-trigger", value: "change")
    }
}

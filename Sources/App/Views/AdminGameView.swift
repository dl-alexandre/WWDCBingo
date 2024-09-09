import Plot

struct AdminGameView: Component {
    let games: [BingoGameState]
    
    var body: Component {
        Div {
            H1("Edit Games")
            for game in games {
                if let gameID = try? game.requireID() {
                    Label("") {
                        Div {
                            Text(gameID.uuidString)
                            Input(type: .button,
                                  value: "Delete"
                            )
                        }
                    }
                    .attribute(named: "hx-delete", value: "/games/\(gameID)")
                    .attribute(named: "hx-include", value: "this")
                } else {
                    Div {
                        Text("Invalid: \(game)")
                    }
                }
            }
        }
        .class("main")
    }
}

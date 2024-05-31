import Plot
import Vapor

struct WebView {
    static func renderPage(_ bodyContent: Component) -> String {
        return HTML(head: [
            .meta(.charset(.utf8)),
            .title("WWDC Bingo 2024!"),
            .link(.href("/style.css"), .rel(.stylesheet)),
            .script(.src("https://unpkg.com/htmx.org@1.9.12")),
            .script(.src("https://unpkg.com/htmx.org@1.9.12/dist/ext/ws.js")),
            .script(.src("https://unpkg.com/htmx.org@1.9.12/dist/ext/json-enc.js")),
            .script(.src("https://unpkg.com/htmx.org@1.9.12/dist/ext/loading-states.js")),
        ], body: { bodyContent })
        .render()
    }
    
    static func body(_ content: Component? = nil, user: User?, isAdmin: Bool = false ) -> Component {
        Div {
            if let content {
                content
            } else {
                Header {
                    H1 {
                        Text("WWDC Bingo 2024!")
                    }
                    Div {
                        if let user {
                            LogoutView(userName: user.email, isAdmin: isAdmin)
                            Link(url: "/tiles/view") {
                                Text("Tiles")
                            }
                        } else {
                                Button {
                                    Text("Customize")
                                }
                                .id("btn-customize")
                                .attribute(named: "hx-post", value: "/customize")
                                .attribute(named: "hx-target", value: "#customize")
                        }
                    }
                    .id("customize")
                }
                Div {
                    Text("You’ll need JavaScript enabled to play")
                    H3 {
                        Text("WWDC Bingo 2024 Game Time!")
                    }
                    H4 {
                        Text("Come back June 10")
                    }
                    Paragraph {
                        Text("Every year Apple releases new veresions of its operating systems: iOS for iPhone, iPad OS for iPad, macOS for Macs, watchOS for Apple Watch, and visionOS for Apple Vision Pro.")
                    }
                    Paragraph {
                        Text("WWDC Bingo lets us play along with their show. We put rumors, hopes, dreams, and fears into game tiles. If they happen then the tile gets marked. Connect five in a row, column, or diagonal and you win*!")
                    }
                    Paragraph {
                        Node.small("* fake internet points")
                    }
                }
                .id("bingo-loading")
                .attribute(named: "hx-swap", value: "outerHTML")
                .attribute(named: "hx-get", value: "/games/view/random")
                .attribute(named: "hx-trigger", value: "load")
                Footer {
                    Span {
                        Text("By ")
                        Link("Michael Critz", url: "https://michaelcritz.com")
                    }
                }
            }
        }
        .id("main")
    }
    
    static func homePage(_ user: User? = nil, isAdmin: Bool = false) -> String {
        Self.renderPage(Self.body(user: user, isAdmin: isAdmin))
    }
}

// MARK: Vapor specific
extension WebView {
    static func response(for bodyContent: Component, user: User? = nil) -> Response {
        return Response(status: .ok, body: .init(stringLiteral: Self.renderPage(bodyContent)))
    }
}

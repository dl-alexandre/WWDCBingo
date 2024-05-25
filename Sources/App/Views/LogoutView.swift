import Plot

struct LogoutView: Component {
    let userName: String
    
    var body: Component {
        Div {
            Button {
                Text("Logout \(userName)")
            }
            .id("logout")
            .attribute(named: "hx-post", value: "/users/logout")
            .attribute(named: "hx-target", value: "#customize")
            .attribute(named: "hx-swap", value: "innerHTML")
        }
        .id("customize")
    }
}

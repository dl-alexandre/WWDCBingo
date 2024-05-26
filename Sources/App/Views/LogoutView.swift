import Plot

struct LogoutView: Component {
    let userName: String
    let isAdmin: Bool
    
    var body: Component {
        Div {
            Text(userName)
            if isAdmin {
                Text(" (admin)")
            }
            Button {
                Text("Logout")
            }
            .id("logout")
            .attribute(named: "hx-post", value: "/users/logout")
            .attribute(named: "hx-target", value: "#customize")
            .attribute(named: "hx-swap", value: "innerHTML")
        }
        .id("customize")
    }
}

import Plot

struct LoginView: Component {
    var body: Component {
        Div {
            Form(url: "/users/login", method: .post) {
                Label("Email") {
                    Input(type: .email, name: "username", isRequired: true, placeholder: "Email")
                }
                Label("Password") {
                    Input(type: .password, name: "password", isRequired: true)
                }
                Input(type: .submit, name: "Sign In")
            }
            .id("login")
            .attribute(named: "hx-post", value: "/users/login")
            .attribute(named: "hx-encoding", value: "json")
            .attribute(named: "hx-target", value: "#customize")
            Button {
                Text("Cancel")
            }
            .attribute(named: "hx-post", value: "/customize/cancel")
            .attribute(named: "hx-target", value: "#customize")
        }
        .id("customize")
    }
}

import Fluent
import Plot
import Vapor

struct CustomizeController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let customize = routes.grouped("customize")
        customize.post { try await self.handleCustomize(req: $0) }
        customize.post("cancel") { _ in 
            return Button {
                Text("Admin")
            }
            .id("btn-customize")
            .attribute(named: "hx-post", value: "/customize")
            .attribute(named: "hx-target", value: "#customize")
            .render()
        }
    }
    
    func handleCustomize(req: Request) async throws -> String {
        guard let user = req.auth.get(User.self) else {
            return LoginView().render()
        }
        let isAdmin = try await user.isAdmin(db: req.db)
        return LogoutView(userName: user.email, isAdmin: isAdmin).render()
    }
}

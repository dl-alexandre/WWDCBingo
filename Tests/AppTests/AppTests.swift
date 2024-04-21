@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testHealthCheck() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        try app.test(.GET, "healthcheck", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    func testLogin() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        try app.test(.POST, "login") { res in
            XCTAssertEqual(res.status, .unauthorized)
        }
    }
    
    
    /// Tests here will fail if running in Xcode without setting the working directory
    /// to the current web project.
    /// See [vapor docs](https://docs.vapor.codes/getting-started/xcode/#custom-working-directory)
    func testWeb() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        try app.test(.GET, "/") { res in
            XCTAssertEqual(res.status, .ok, "Using Xcode? Set the working directory to the project folder. See: https://docs.vapor.codes/getting-started/xcode/#custom-working-directory")
            let body = res.body
            XCTAssertContains(res.content.contentType?.description, "text/html")
            XCTAssertContains(body.string, "WWDC Bingo")
        }
    }
    
    // MARK: Admin
    func testAdminAuth() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        
        guard let email = ServerConfig.adminUserPublic.email,
              let pass = ServerConfig.adminUserPublic.password else {
            XCTFail("Misconfiguration")
            return
        }
        
        let basicAuth = BasicAuthorization(username: email,
                                           password: pass)
        var headers = HTTPHeaders()
        headers.basicAuthorization = basicAuth
        
        
        var jwtToken: String?
        try app.test(.POST, "login", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertNotNil(res.body)
            XCTAssertNoThrow({
                let bodyDict = try res.content.decode([String: String].self)
                jwtToken = try XCTUnwrap(bodyDict["jwt"])
                
                headers = HTTPHeaders([("Authorization", "Bearer \(jwtToken!)")])
                try app.test(.GET, "jwt", headers: headers) { res in
                    XCTAssertEqual(res.status, .ok)
                }
                
                try app.test(.GET, "users", headers: headers) { res in
                    XCTAssertEqual(res.status, .ok)
                }
                
                try app.test(.GET, "tiles", headers: headers) { res in
                    XCTAssertEqual(res.status, .ok)
                }
                
                try app.test(.GET, "games", headers: headers) { res in
                    XCTAssertEqual(res.status, .ok)
                }
            })
        }
    }
}

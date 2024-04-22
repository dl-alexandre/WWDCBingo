@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    var app = Application(.testing)
    var headers = HTTPHeaders()
    
    override func setUp() async throws {
        try await configure(app)
        try await app.startup()
    }
    
    override func tearDown() async throws {
        headers = HTTPHeaders()
        app.shutdown()
    }
    
    private func loginAdmin(_ app: Application) throws {
        guard let email = ServerConfig.adminUserPublic.email,
              let pass = ServerConfig.adminUserPublic.password else {
            fatalError("Misconfiguration")
        }
        
        let basicAuth = BasicAuthorization(username: email,
                                           password: pass)
        headers.basicAuthorization = basicAuth
        
        var jwtToken: String?
        try app.test(.POST, "login", headers: headers) { res in
            let bodyDict = try res.content.decode([String: String].self)
            jwtToken = try XCTUnwrap(bodyDict["jwt"])
            headers.basicAuthorization = nil
            headers = HTTPHeaders([("Authorization", "Bearer \(jwtToken!)")])
        }
    }
    
    func testHealthCheck() async throws {
        try app.test(.GET, "healthcheck", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    func testLogin() async throws {
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
        guard let email = ServerConfig.adminUserPublic.email,
              let pass = ServerConfig.adminUserPublic.password else {
            XCTFail("Misconfiguration")
            return
        }
        
        let basicAuth = BasicAuthorization(username: email,
                                           password: pass)
        headers.basicAuthorization = basicAuth
        
        var jwtToken: String?
        try app.test(.POST, "login", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertNotNil(res.body)
            XCTAssertNoThrow({ [self] in
                let bodyDict = try res.content.decode([String: String].self)
                jwtToken = try XCTUnwrap(bodyDict["jwt"])
                
                headers = HTTPHeaders([("Authorization", "Bearer \(jwtToken!)")])
                try app.test(.GET, "jwt", headers: headers) { res in
                    XCTAssertEqual(res.status, .ok)
                }
            })
        }
    }
    
    func testAdminRoutes() async throws {
        try loginAdmin(app)
        
        try app.test(.GET, "users", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
        }
        
        try app.test(.GET, "tiles", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
        }
        
        try app.test(.GET, "games", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
}

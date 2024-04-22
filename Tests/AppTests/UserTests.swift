@testable import App
import XCTVapor

final class UserTests: XCTestCase {
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
    
    func testGetUsers() throws {
        // Not logged in
        try app.test(.GET, "users") { res in
            XCTAssertEqual(res.status, .unauthorized)
        }

        try loginAdmin(app)
        try app.test(.GET, "users", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertNoThrow {
                let users = try res.content.decode([User].self)
                XCTAssertNotNil(users)
                XCTAssertGreaterThan(users.count, 0)
            }
        }
    }
}

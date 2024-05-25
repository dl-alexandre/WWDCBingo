import Fluent
import Vapor

/// `User` class for server usage.
/// Do not use `User` over the wire because we don’t want the
/// `User.password` to leak. Use the ``UserPublic`` type instead.
public final class User: Model, Content {
    public static let schema = "users"
    
    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: "given_name")
    var givenName: String
    
    @Field(key: "family_name")
    var familyName: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Siblings(through: UserTag.self, from: \.$user, to: \.$tag)
    public var tags: [Tag]
    
    @Children(for: \.$user)
    var bingoGames: [BingoGameState]
    
    public init() { /* no op */}
    
    init(id: UUID?, givenName: String, familyName: String, email: String, passwordHash: String) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
        self.passwordHash = passwordHash
    }
    
    init(id: UUID?, givenName: String, familyName: String, email: String, password: String) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
    }
    
    init?(userPublic: UserPublic) {
        guard let email = userPublic.email,
              let pass = userPublic.password,
              let passHash = try? Self.createPasswordHash(pass) else {
            return
        }
        self.givenName = userPublic.givenName
        self.familyName = userPublic.familyName
        self.email = email
        self.passwordHash = passHash
    }
}

// MARK: Authenticatable
extension User: Authenticatable {
    static func createPasswordHash(_ password: String) throws -> String {
        guard let passData = password.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "Could not store password")
        }
        return SHA512.hash(data: passData).hexEncodedString()
    }
    func authenticate(email: String, password: String) throws {
        guard let passData = password.data(using: .utf8),
              email == self.email,
              SHA256.hash(data: passData).hexEncodedString() == self.passwordHash else {
            throw Abort(.unauthorized)
        }
    }
}

// MARK: ModelAuthenticatable, ModelCredentialsAuthenticatable
extension User: ModelAuthenticatable, ModelCredentialsAuthenticatable {
    public static var usernameKey: KeyPath<User, Field<String>> {
        \User.$email
    }
    
    public static var passwordHashKey: KeyPath<User, Field<String>> {
        \User.$passwordHash
    }
    
    public func verify(password: String) throws -> Bool {
        guard let loginPasswordData = password.data(using: .utf8) else {
            throw Abort(.internalServerError)
        }
        let loginPasswordHash = SHA512.hash(data: loginPasswordData).hexEncodedString()
        return loginPasswordHash == self.passwordHash
    }
}

// MARK: SessionAuthenticatable
extension User: SessionAuthenticatable {
    public var sessionID: UUID {
        self.id ?? UUID() // We can’t just crash here
    }
}

struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    
    func authenticate(sessionID: UUID, for request: Request) async throws {
        guard let user = try await User.find(sessionID, on: request.db) else {
            throw Abort(.unauthorized)
        }
        request.auth.login(user)
    }
}

// MARK: Admin
extension User {
    func isAdmin(db: Database) async throws -> Bool {
        let adminTagCount = try await self.$tags.query(on: db)
            .filter(\.$name == ServerConfig.adminTagName)
            .count()
        return adminTagCount == 1
    }
}

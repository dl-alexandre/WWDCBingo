import Fluent
import Vapor

/// `User` class for server usage.
/// Do not use `User` over the wire because we don’t want the
/// `User.password` to leak. Use the ``UserPublic`` type instead.
final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
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
    
    init() { /* no op */}
    
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
              let passData = pass.data(using: .utf8) else {
            return
        }
        let passHash = SHA512.hash(data: passData).hexEncodedString()
        self.givenName = userPublic.givenName
        self.familyName = userPublic.familyName
        self.email = email
        self.passwordHash = passHash
    }
}

extension User: Authenticatable { }

// MARK: Admin
extension User {
    // TODO: Update this to be authorative
    func isAdmin() -> Bool {
        self.tags.contains { tag in
            tag.name == "Admin"
        }
    }
}

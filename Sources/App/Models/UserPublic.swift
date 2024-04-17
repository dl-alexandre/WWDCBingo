import Vapor

/// This Type is the public values of a ``User`` class
public struct UserPublic: Codable {
    let id: UUID?
    let givenName: String
    let familyName: String
    let email: String?
    let password: String?
}

extension UserPublic {
    init(user: User) {
        self.id = user.id
        self.givenName = user.givenName
        self.familyName = user.familyName
        self.email = user.email
        self.password = nil // do not send passwords over the wire
    }
}

import JWT
import Vapor

struct SessionToken: Content, Authenticatable, JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case userID = "uid"
    }
    
    let subject: SubjectClaim
    let expiration: ExpirationClaim
    let userID: UUID
    
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}

extension SessionToken {
    init(user: User) throws {
        self.subject = SubjectClaim(value: user.email)
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(60 * 60 * 25)) // 60sec * 60min * 25hr
        self.userID = try user.requireID()
    }
}

extension SessionToken: SessionAuthenticatable {
    var sessionID: String {
        return userID.uuidString
    }
}

import Fluent
import JWT
import Vapor

extension Request {
    public func registeredUser() async throws -> User {
        let jwtToken = try jwt.verify(as: SessionToken.self)
        let uid = jwtToken.userID
        guard let foundUser = try await User.find(uid, on: db) else {
            logger.warning("Unregistered access attempt")
            throw Abort(.badRequest)
        }
        return foundUser
    }
    
    @discardableResult
    public func adminUser() async throws -> User? {
        let user = try await registeredUser()
        guard try await user.isAdmin(db: self.db) else {
            throw Abort(.unauthorized)
        }
        return user
    }
}

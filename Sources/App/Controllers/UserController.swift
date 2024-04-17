import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: { try await self.index(req: $0) })
        users.post(use: { try await self.create(req: $0) })
        users.get("tags") { try await self.getTags(req: $0) }
        
        users.group(":userID") { user in
            user.get(use: { try await self.get(req: $0) })
            user.put(use: { try await self.update(req: $0) })
            user.delete(use: { try await self.delete(req: $0) })
            user.get("tags") { try await self.adminGetTagsForUser(req: $0) }
            user.post("tags", ":tagID") { try await self.adminAddTagOnUser(req: $0) }
        }
    }

}

// MARK: - CRUD
extension UserController {
    // Allows an admin to see all users
    func index(req: Request) async throws -> Page<UserPublic> {
        let user = try req.auth.require(User.self)
        guard user.isAdmin() else {
            throw Abort(.unauthorized)
        }
        let allUsers = try await User.query(on: req.db).paginate(for: req)
        let thesePublicUsers = allUsers.map { UserPublic(user: $0) }
        return thesePublicUsers
    }
    
    // Creates a `User` and returns a `UserPublic` without a password
    func create(req: Request) async throws -> UserPublic {
        let publicUser = try req.content.decode(UserPublic.self)
        guard let user = User(userPublic: publicUser) else {
            throw Abort(.badRequest,
                         reason: "Not a valid user: \(publicUser)",
                         identifier: "Error: Liger", 
                        suggestedFixes: [
                            "Ensure email and password are not blank",
                            "Password must be equal to or greater than 7 characters"
            ])
        }
        if let uid = publicUser.id {
            let savedUser = try await User.find(uid, on: req.db)
            guard savedUser == nil else {
                req.logger.error(.init(stringLiteral: "User exists. user.id: \(savedUser?.id?.uuidString ?? "-")"))
                throw Abort(.badRequest)
            }
        }
        try await user.save(on: req.db)
        return UserPublic(user: user)
    }
    
    func get(req: Request) async throws -> UserPublic {
        let user = try await registeredUser(req: req)
        
        // Looking at myself
        if user.id == req.parameters.get(":userID") {
            return UserPublic(user: user)
        }
        
        // Admin looking for someone
        if user.isAdmin(),
           let foundUser = try await User.find(req.parameters.get(":userID"), on: req.db) {
            return UserPublic(user: foundUser)
        }
        
        // Not an Admin but looking for someone else
        throw Abort(.unauthorized)
    }
    
    func delete(req: Request) async throws -> HTTPResponseStatus {
        let user = try await registeredUser(req: req)
        guard let userIDParam = req.parameters.get(":userID"),
              let uid = UUID(uuidString: userIDParam) else {
            throw Abort(.badRequest)
        }
        
        if try user.isAdmin() && user.requireID() == uid {
            throw Abort(.badRequest, reason: "You cannot remove yourself because you are an `Admin`")
        }
        
        // Deleting myself
        if try user.requireID() == uid {
            try await user.delete(on: req.db)
        }
        
        guard user.isAdmin() else {
            throw Abort(.unauthorized)
        }
        
        if let userToDelete = try await User.find(uid, on: req.db) {
            try await userToDelete.delete(on: req.db)
            return .ok
        }
        
        return .badRequest
    }
    
    func update(req: Request) async throws -> UserPublic {
        let registeredUser = try await registeredUser(req: req)
        let publicUser = try req.content.decode(UserPublic.self)
        guard let uid = publicUser.id,
              try uid == registeredUser.requireID(),
              let updatedUser = User(userPublic: publicUser) else {
            req.logger.warning(.init(stringLiteral: "Not a valid user"))
            throw Abort(.badRequest)
        }
        guard let savedUser = try await User.find(uid, on: req.db) else {
            req.logger.warning(.init(stringLiteral: "User does not exist. user.id: \(publicUser.id?.uuidString ?? "-")"))
            throw Abort(.badRequest)
        }
        
        try await updatedUser.save(on: req.db)
        return UserPublic(user: updatedUser)
    }
}

// MARK: - User+Tag
extension UserController {
    /// Gets the current user’s tags
    func getTags(req: Request) async throws -> [Tag] {
        let user = try await registeredUser(req: req)
        return user.tags
    }
    
    /// Gated by admin access
    func adminGetTagsForUser(req: Request) async throws -> [Tag] {
        guard let uidParam = req.parameters.get(":userID"),
              let userIDtoQuery = UUID(uuidString: uidParam) else {
            throw Abort(.badRequest)
        }
        let user = try await registeredUser(req: req)
        guard user.isAdmin() else {
            req.logger.warning("Unauthorized access attempt")
            throw Abort(.unauthorized)
        }
        guard let userToQuery = try await User.find(userIDtoQuery, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        return userToQuery.tags
    }
    
    func addTag(req: Request) async throws -> HTTPResponseStatus {
        async let user = registeredUser(req: req)
        guard let tagID = req.parameters.get(":tagID"),
              let tagUUID = UUID(uuidString: tagID) else {
            throw Abort(.badRequest)
        }
        async let tag = Tag.find(tagUUID, on: req.db)
        
        // Only Admins can make other admins
        guard let tag = try await tag,
              tag.name != "Admin" else {
            req.logger.warning("Unregistered access attempt")
            throw Abort(.unauthorized)
        }
        try await user.$tags.attach(tag, on: req.db)
        return .ok
    }
    
    func adminAddTagOnUser(req: Request) async throws -> HTTPResponseStatus {
        async let admin = adminUser(req: req)
        guard let userID = req.parameters.get(":userID"),
              let uid = UUID(uuidString: userID),
              let tagID = req.parameters.get(":tagID"),
              let tid = UUID(uuidString: tagID) else {
            throw Abort(.badRequest)
        }
        async let user = User.find(uid, on: req.db)
        async let tag = Tag.find(tid, on: req.db)
        guard let user = try await user,
                let tag = try await tag,
                let _ = try await admin else {
            throw Abort(.failedDependency)
        }
        try await user.$tags.attach(tag, on: req.db)
        
        // TODO: Log changes
        return .ok
    }
}


// MARK: - Helpers
extension UserController {
    private func registeredUser(req: Request) async throws -> User {
        let user = try req.auth.require(User.self)
        let uid = try user.requireID()
        guard let foundUser = try await User.find(uid, on: req.db) else {
            req.logger.warning("Unregistered access attempt")
            throw Abort(.badRequest)
        }
        return foundUser
    }
    
    @discardableResult
    private func adminUser(req: Request) async throws -> User? {
        let user = try await registeredUser(req: req)
        guard user.isAdmin() else {
            throw Abort(.unauthorized)
        }
        return user
    }
}

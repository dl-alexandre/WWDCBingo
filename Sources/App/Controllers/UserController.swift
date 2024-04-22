import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersProtected = routes.grouped(SessionToken.asyncAuthenticator(), SessionToken.guardMiddleware())
        let users = usersProtected.grouped("users")
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
        let user = try await req.registeredUser()
        guard try await user.isAdmin(db: req.db) else {
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
        let user = try await req.registeredUser()
        
        // Looking at myself
        if user.id == req.parameters.get("userID") {
            return UserPublic(user: user)
        }
        
        // Admin looking for someone
        if try await user.isAdmin(db: req.db),
           let foundUser = try await User.find(req.parameters.get("userID"), on: req.db) {
            return UserPublic(user: foundUser)
        }
        
        // Not an Admin but looking for someone else
        throw Abort(.unauthorized)
    }
    
    func delete(req: Request) async throws -> HTTPResponseStatus {
        let user = try await req.registeredUser()
        guard let userIDParam = req.parameters.get("userID"),
              let uid = UUID(uuidString: userIDParam) else {
            throw Abort(.badRequest)
        }
        
        if try await user.isAdmin(db: req.db) && user.requireID() == uid {
            throw Abort(.badRequest, reason: "You cannot remove yourself because you are an `Admin`")
        }
        
        // Deleting myself
        if try user.requireID() == uid {
            try await user.$tags.detachAll(on: req.db)
            try await user.delete(on: req.db)
        }
        
        guard try await user.isAdmin(db: req.db) else {
            throw Abort(.unauthorized)
        }
        
        if let userToDelete = try await User.find(uid, on: req.db) {
            try await userToDelete.$tags.detachAll(on: req.db)
            try await userToDelete.delete(on: req.db)
            return .ok
        }
        
        return .badRequest
    }
    
    func update(req: Request) async throws -> UserPublic {
        let registeredUser = try await req.registeredUser()
        let publicUser = try req.content.decode(UserPublic.self)
        // FIXME: This always fails
        guard let uid = publicUser.id,
              try uid == registeredUser.requireID() else {
            req.logger.warning(.init(stringLiteral: "Not a valid user"))
            throw Abort(.badRequest)
        }
        let savedUser = try await User.find(uid, on: req.db)
        guard let savedUser else {
            req.logger.warning(.init(stringLiteral: "User does not exist. user.id: \(publicUser.id?.uuidString ?? "-")"))
            throw Abort(.badRequest)
        }
        savedUser.email = publicUser.email ?? savedUser.email
        savedUser.familyName = publicUser.familyName
        savedUser.givenName = publicUser.givenName
        if let password = publicUser.password {
            savedUser.passwordHash = try User.createPasswordHash(password)
        }
        try await savedUser.save(on: req.db)
        return UserPublic(user: savedUser)
    }
}

// MARK: - User+Tag
extension UserController {
    /// Gets the current user’s tags
    func getTags(req: Request) async throws -> [Tag] {
        let user = try await req.registeredUser()
        if user.$tags.value != nil {
            return user.tags
        }
        return try await user.$tags.get(on: req.db)
    }
    
    /// Gated by admin access
    func adminGetTagsForUser(req: Request) async throws -> [Tag] {
        guard let uidParam = req.parameters.get("userID"),
              let userIDtoQuery = UUID(uuidString: uidParam) else {
            throw Abort(.badRequest)
        }
        let user = try await req.registeredUser()
        guard try await user.isAdmin(db: req.db) else {
            req.logger.warning("Unauthorized access attempt")
            throw Abort(.unauthorized)
        }
        guard let userToQuery = try await User.find(userIDtoQuery, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        return try await userToQuery.$tags.get(on: req.db)
    }
    
    func addTag(req: Request) async throws -> HTTPResponseStatus {
        async let user = req.registeredUser()
        guard let tagID = req.parameters.get("tagID"),
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
        
        // Do not attach the same tag multiple times
        let savedTagID = try tag.requireID()
        let alreadyMatchedTags = try await user.$tags.query(on: req.db).filter(\Tag.$id, .equal, savedTagID).count()
        guard alreadyMatchedTags == 0 else {
            return .ok // Already has tag
        }
        try await user.$tags.attach(tag, on: req.db)
        return .ok
    }
    
    func adminAddTagOnUser(req: Request) async throws -> HTTPResponseStatus {
        async let admin = req.adminUser()
        guard let userID = req.parameters.get("userID"),
              let uid = UUID(uuidString: userID),
              let tagID = req.parameters.get("tagID"),
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
        let savedTagID = try tag.requireID()
        let alreadyMatchedTags = try await user.$tags.query(on: req.db).filter(\Tag.$id, .equal, savedTagID).count()
        guard alreadyMatchedTags == 0 else {
            return .ok // Already has tag
        }
        try await user.$tags.attach(tag, on: req.db)
        
        // TODO: Log changes
        return .ok
    }
}

import Fluent
import Vapor

struct TilePublic: Codable {
    var id: UUID?
    var title: String
    var isPlayed: Bool
    var userID: UUID?
}

extension TilePublic {
    func makeTile(on req: Request) async throws -> Tile {
        let user = try await req.registeredUser()
        return try Tile(id: id, title: title, isPlayed: isPlayed, user: user)
    }
}

final class Tile: Model, Content {
    static let schema = "tiles"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "played")
    var isPlayed: Bool
    
    @Parent(key: "user_id")
    var user: User

    init() { /* Fluent magic */ }

    init(id: UUID? = nil, title: String, isPlayed: Bool = false, user: User) throws {
        self.id = id
        self.title = title
        self.isPlayed = isPlayed
        self.$user.id = try user.requireID()
    }
}

extension Tile {
    /// Create a ``TilePublic`` that does not expose ``User.id``
    func makePublic() -> TilePublic {
        TilePublic(id: id,
                   title: title,
                   isPlayed: isPlayed,
                   userID: nil)
    }
}

import Fluent
import Vapor

final class UserTile: Model {
    static let schema = "user_tile"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "tag_id")
    var tag: Tag
    
    init() { }
}

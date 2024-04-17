import Fluent
import Vapor

final class UserTag: Model {
    static let schema = "user+tag"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "tag_id")
    var tag: Tag
    
    init() { }
}

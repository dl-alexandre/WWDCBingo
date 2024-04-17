import Fluent
import Vapor

final class Tag: Model, Content {
    static let schema = "tags"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: UserTag.self, from: \.$tag, to: \.$user)
    public var users: [User]
    
    init() { /* no op */ }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

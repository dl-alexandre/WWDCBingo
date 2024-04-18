import Fluent
import Vapor

public  final class Tag: Model, Content {
    public static let schema = "tags"
    
    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: UserTag.self, from: \.$tag, to: \.$user)
    public var users: [User]
    
    public init() { /* no op */ }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

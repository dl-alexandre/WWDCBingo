import Fluent
import Vapor

final class Tile: Model, Content {
    static let schema = "tiles"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "played")
    var isPlayed: Bool

    init() { /* no op */ }

    init(id: UUID? = nil, title: String, isPlayed: Bool = false) {
        self.id = id
        self.title = title
        self.isPlayed = isPlayed
    }
}

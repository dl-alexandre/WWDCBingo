import Fluent

extension Tile {
    static func hydrate(on db: Database) async throws {
        guard let admin = try await User.query(on: db)
            .filter(\.$email == ServerConfig.adminUserPublic.email!)
            .first() else {
            fatalError("Cannot hydrate because admin user could not be found")
        }
        let tiles = [
            try Tile(title: "Good Morning!", user: admin),
            try Tile(title: "Craig hair goof", user: admin),
            try Tile(title: "Through the floor", user: admin),
            try Tile(title: "Johny Srouji", user: admin),
            try Tile(title: "AI + Music", user: admin),
            try Tile(title: "AI + Pages", user: admin),
            try Tile(title: "AI + Keynote", user: admin),
            try Tile(title: "AI + Xcode", user: admin),
            try Tile(title: "Spotlight", user: admin),
            try Tile(title: "Siri + LLM", user: admin),
            try Tile(title: "Siri + Messages", user: admin),
            try Tile(title: "Shortcuts", user: admin),
            try Tile(title: "Some visionOS design in iOS", user: admin),
            try Tile(title: "Home Screen icons anywhere", user: admin),
            try Tile(title: "Apple Maps", user: admin),
            try Tile(title: "RCS + Messages", user: admin),
            try Tile(title: "Mac mini", user: admin),
            try Tile(title: "Mac Studio", user: admin),
            try Tile(title: "Mac Pro", user: admin),
            try Tile(title: "Customize Apple Watch Button", user: admin),
            try Tile(title: "visionOS 2", user: admin),
            try Tile(title: "Vision Pro + phone call", user: admin),
            try Tile(title: "Vision Pro + gestures", user: admin),
            try Tile(title: "iOS 18 runs on iPhone XR", user: admin),
            try Tile(title: "New Siri design", user: admin),
            try Tile(title: "AI + App Store", user: admin),
            try Tile(title: "AI API", user: admin),
            try Tile(title: "Custom AI model", user: admin),
            try Tile(title: "tvOS", user: admin),
            try Tile(title: "Maps", user: admin),
        ]
        for tile in tiles {
            try await tile.save(on: db)
        }
    }
}

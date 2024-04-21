import PostgresKit

actor ServerConfig {
    static let siteDomainName = "wwdcbingo.com"
    static let adminTagName = "Admin"
    static let jwtSignerKey = "66e66e4d199a86baa1c80f40b3df51997d6e295267ad8cfe75c257a9513d87789d166d49a9c9745bedf938dbcbc016900495f2f33e4e8bb9d81799e032053953"
    static let adminUserPublic = UserPublic(id: nil,
                                            givenName: "System",
                                            familyName: "Admin",
                                            email: "admin@example.com",
                                            password: "2 Super secreT 4 U!")
    static let adminTag = Tag(name: adminTagName)
}

extension ServerConfig {
    static func postgresConfiguration() throws -> SQLPostgresConfiguration { 
        SQLPostgresConfiguration(hostname: "localhost",
                                 port: 5432,
                                 username: "mcritz",
                                 password: nil,
                                 database: nil,
                                 tls: .prefer(try .init(configuration: .clientDefault)))
    }
}

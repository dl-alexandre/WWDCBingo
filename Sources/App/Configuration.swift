import PostgresKit

actor Configuration {
    static let siteDomainName = "wwdcbingo.com"
    static let adminTagName = "Admin"
    static let adminUserPublic = UserPublic(id: nil,
                                            givenName: "System",
                                            familyName: "Admin",
                                            email: "admin@example.com",
                                            password: "2 Super secreT 4 U!")
    static let adminTag = Tag(name: adminTagName)
}

extension Configuration {
    static func postgresConfiguration() throws -> SQLPostgresConfiguration { 
        SQLPostgresConfiguration(hostname: "localhost",
                                 port: 5432,
                                 username: "mcritz",
                                 password: nil,
                                 database: nil,
                                 tls: .prefer(try .init(configuration: .clientDefault)))
    }
}

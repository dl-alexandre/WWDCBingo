import PostgresKit

actor ServerConfig {
    static let siteDomainName = "wwdcbingo.com"
    static let adminTagName = "Admin"
    static let jwtSignerKey = "e74cd783ad64e74bf8c76d96bf997f27bba93e53f7611069c68c13f60e06f94de535e103e595d5412307fc5be5b0a9e9636cad765f48a6e29f5d1eed9f3c6197"
    static let adminUserPublic = UserPublic(id: nil,
                                            givenName: "System",
                                            familyName: "Admin",
                                            email: "wwdc@michaelcritz.com",
                                            password: "Y3ll0wb4ll!ww")
    static let adminTag = Tag(name: adminTagName)
}

extension ServerConfig {
    static func postgresConfiguration() throws -> SQLPostgresConfiguration {
        #if DEBUG
        SQLPostgresConfiguration(hostname: "localhost",
                                 port: 5432,
                                 username: "mcritz",
                                 password: "",
                                 database: "",
                                 tls: .prefer(try .init(configuration: .clientDefault)))
        #else
        SQLPostgresConfiguration(hostname: "db",
                                 port: 5432,
                                 username: "vapor_username",
                                 password: "vapor_password",
                                 database: "vapor_database",
                                 tls: .prefer(try .init(configuration: .clientDefault)))
        #endif
    }
}

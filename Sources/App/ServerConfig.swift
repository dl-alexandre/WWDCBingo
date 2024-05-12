import PostgresKit
import Vapor

actor ServerConfig {
    static let siteDomainName = Environment.get("BINGO_SITE_DOMAIN_NAME")
    static let adminTagName = "Admin"
    static let jwtSignerKey = Environment.get("BINGO_JWT_SIGNER_KEY")
    static let adminUserPublic = UserPublic(id: nil,
                                            givenName: "System",
                                            familyName: "Admin",
                                            email: Environment.get("BINGO_ADMIN_EMAIL"),
                                            password: Environment.get("BINGO_ADMIN_PASSWORD"))
    static let adminTag = Tag(name: adminTagName)
}

extension ServerConfig {
    static func postgresConfiguration() throws -> SQLPostgresConfiguration {
        guard let dbDomain      = Environment.get("BINGO_SITE_DOMAIN_NAME"),
              let dbPortString  = Environment.get("BINGO_DB_PORT"),
              let dbPort        = Int(dbPortString) else {
            throw Errors.misconfigured(reason: """
                Environment misconfigured.
                Copy the `env-example` file to `.env` then edit the values as needed.
            """)
        }
        let dbUser      = Environment.get("BINGO_DB_USER") ?? ""
        let dbPassword  = Environment.get("BINGO_DB_PASSWORD") ?? ""
        let dbName      = Environment.get("BINGO_DB_NAME") ?? ""
        return SQLPostgresConfiguration(hostname: dbDomain,
                                         port: dbPort,
                                         username: dbUser,
                                         password: dbPassword,
                                         database: dbName,
                                         tls: .prefer(try .init(configuration: .clientDefault)))
    }
}

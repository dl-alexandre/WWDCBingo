enum Permission: String, Codable {
    case viewOnly
    case userPublic
    case userPrivate
    case adminPrivate
    case adminPublic
}

import Fluent
import Vapor

extension UserPublic: Content { }

extension UserPublic: Validatable {
    public static func validations(_ validations: inout Vapor.Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(7...))
    }
}

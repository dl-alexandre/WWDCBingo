import Vapor

extension Int {
    func middle() -> Int {
        Int(ceil(Double(self) / 2))
    }
}

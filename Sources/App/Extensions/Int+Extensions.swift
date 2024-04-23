import Darwin.C.math

extension Int {
    func middle() -> Int {
        Int(ceil(Double(self) / 2))
    }
}

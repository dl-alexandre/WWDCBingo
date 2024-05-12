import Vapor

struct WebSocketClientsKey: StorageKey {
    typealias Value = WebSocketClients
}

actor WebSocketClients {
    typealias connectionID = String
    var clients = [connectionID: WebSocket]()
    
    func add(id: connectionID, ws: WebSocket) {
        clients[id] = ws
    }
    
    func remove(id: connectionID) {
        clients[id] = nil
    }
    
    func sendToAll(bytes: ByteBuffer) {
        for client in clients {
            client.value.send(bytes)
        }
    }
    
    func sendToAll(text: String) {
        for client in clients {
            client.value.send(text)
        }
    }
}

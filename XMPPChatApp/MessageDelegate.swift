import Foundation

protocol MessageDelegate {
    func newMessageReceived(_ messageContent: String, user: String)
}


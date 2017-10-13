import Foundation
import XMPPFramework

enum XMPPControllerError: Error {
    case wrongUserJID
}

class XMPPController: NSObject {
    
    var xmppStream: XMPPStream
    
    let hostName: String
    let userJID: XMPPJID
    let hostPort: UInt16
    let password: String
    
    var xmppRosterStorage: XMPPRosterCoreDataStorage!

    var xmppRoster: XMPPRoster!
    
    var messageDelegate: MessageDelegate?
    var connectionStatus: ConnectionStatus?
    
    init(hostName: String, userJIDString: String, hostPort: UInt16 = 5222, password: String) throws {
        guard let userJID = XMPPJID(string: userJIDString) else {
            throw XMPPControllerError.wrongUserJID
        }
        
        self.hostName = hostName
        self.userJID = userJID
        self.hostPort = hostPort
        self.password = password
        
        // Stream Configuration
        self.xmppStream = XMPPStream()
        self.xmppStream.hostName = hostName
        self.xmppStream.hostPort = hostPort
        self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed
        self.xmppStream.myJID = userJID
        
        super.init()
        
        self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        
    }
    
    func sendMessage(_ message: String!, _ user: String) {
        if message != nil {
            let senderJID = XMPPJID(string: user)
            let msg = XMPPMessage(type: "chat", to: senderJID)
            
            msg?.addBody(message)
            self.xmppStream.send(msg)
        }
        
    }
    
    func connect() {
        if !self.xmppStream.isDisconnected() {
            return
        }
        
        self.xmppRosterStorage = XMPPRosterCoreDataStorage()
        //contact list provider
        self.xmppRoster = XMPPRoster(rosterStorage: self.xmppRosterStorage as XMPPRosterStorage!)
        self.xmppRoster.activate(self.xmppStream)
        
        try! self.xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)
    }
    
    func disconnect() {
        if self.xmppStream.isDisconnected() {
            return
        }
        self.xmppRoster.deactivate()
        self.xmppRoster = nil
        self.xmppRosterStorage.clearAllResources(for: self.xmppStream)
        self.xmppRosterStorage = nil
        self.xmppStream.disconnect()
        self.connectionStatus?.disconnected()
        print("Stream: Disconnected")
    }
}

extension XMPPController: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ stream: XMPPStream!) {
        print("Stream: Connected")
        try! stream.authenticate(withPassword: self.password)
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        self.xmppStream.send(XMPPPresence())
        self.connectionStatus?.connected()
        print("Stream: Authenticated")
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        print("Stream: Fail to Authenticate")
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceive message: XMPPMessage!) {
        if message.isChatMessageWithBody() {
            let user = self.xmppRosterStorage.user(for: message.from(), xmppStream: sender, managedObjectContext: xmppRosterStorage.mainThreadManagedObjectContext)
            let body = message.body()
            self.messageDelegate?.newMessageReceived(body!, user: (user?.jidStr)!)
            //print("User:" + (user?.jidStr)! + " Body:" + body!)
        } else {
            //was composing
            if let _ = message.forName("composing") {
                
            }
        }
    }
    
}



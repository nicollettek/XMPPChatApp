import Cocoa
import XMPPFramework

class ViewController: NSViewController, ConnectionStatus, MessageDelegate {

    var xmppController: XMPPController!
    @IBOutlet weak var loginStatus: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func connect(_ sender: NSButton) {
        
            do {
                try self.xmppController = XMPPController(hostName: "localhost",
                                                         userJIDString: "admin@localhost",
                                                         password: "12345")
                self.xmppController.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
                self.xmppController.connectionStatus = self
                self.xmppController.messageDelegate = self
                self.xmppController.connect()
            } catch {
                print("Something went wrong")
            }
        
    }
    
    @IBAction func disconnect(_ sender: NSButton) {
        self.xmppController.disconnect()
    }
    
    func connected() {
        self.loginStatus.stringValue = "Login successful"
        self.loginStatus.isHidden = false
    }
    
    func disconnected() {
        self.loginStatus.stringValue = "Disconnected"
        self.xmppController.connectionStatus = nil
        self.xmppController.messageDelegate = nil
    }
    
    func sendMessage(_ message: String, _ user: String) {
        if xmppController != nil {
                if !message.isEmpty {
                    xmppController?.sendMessage(message, user)
                }
        }
    }
    
    func newMessageReceived(_ messageContent: String, user: String) {
        //print("\(messageContent)")
        
        let fileName = "lib/chatbot"
        
        if let filePath = Bundle.main.path(forResource: fileName, ofType: "py") {
            let endIndex = filePath.index(filePath.endIndex, offsetBy: -3)
            let truncated = filePath[..<endIndex]
            print(String(truncated))
            
            let (output, _, status) = runCommand(cmd: "/usr/bin/python",
                                                     args: filePath,
                                                     messageContent )
            print("program exited with status \(status)")
            if output.count > 0 {
                //print("program output:")
                print(output.last!)
                sendMessage(output.last!, user)
            }
//            if error.count > 0 {
//                print("error output:")
//                print(error)
//            }
        }
    }
    
    func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus

        return (output, error, status)
    }

}


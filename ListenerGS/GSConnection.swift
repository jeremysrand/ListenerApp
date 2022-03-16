//
//  GSConnection.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2022-03-14.
//

import Foundation
import os

struct GSConnectionErrorMessage: Identifiable {
    var id: String { message }
    let title: String
    let message: String
}

enum GSConnectionState {
    case disconnected
    case connecting
    case connected
    case listening
    case stoplistening
}

extension GSConnectionState: CustomStringConvertible
{
    var description: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .listening:
            return "listening"
        case .stoplistening:
            return "stop listening"
        }
    }
}

protocol SpeechForwarderProtocol
{
    func startListening() -> Bool
    func stopListening()
}

class GSConnection : ObservableObject {
    @Published var state = GSConnectionState.disconnected
    @Published var textHeard = ""
    @Published var errorMessage : GSConnectionErrorMessage?
    
    var speechForwarder : SpeechForwarderProtocol?
    
    let LISTEN_STATE_MSG = 1
    let LISTEN_TEXT_MSG = 2
    let LISTEN_SEND_MORE = 3
    
    let port = 19026
    private var destination = ""
    private var client: TCPClient?
    
    private let logger = Logger()
    
    private let readQueue = OperationQueue()
    private let writeQueue = OperationQueue()
    
    private var condition = NSCondition()
    private var stopListeningFlag = false
    private var canSend = true
    
    func changeState(newState : GSConnectionState)
    {
        if (state == newState) {
            return;
        }
        
        var legalTransition = false
        switch (newState)
        {
        case .disconnected:
            legalTransition = ((state == .connected) || (state == .connecting))
            
        case .connecting:
            legalTransition = (state == .disconnected)
            
        case .connected:
            legalTransition = ((state == .connecting) || (state == .listening) || (state == .stoplistening))
            
        case .listening:
            legalTransition = (state == .connected)
            
        case .stoplistening:
            legalTransition = ((state == .connected) || (state == .listening))
        }
        
        if (!legalTransition) {
            logger.error("Illegal requested state transition from \(self.state) to \(newState)")
            errorOccurred(title: "Bad State Change", message: "Illegal state transition from \(self.state) to \(newState)")
        } else {
            state = newState
        }
    }
    
    func errorOccurred(title: String, message : String)
    {
        OperationQueue.main.addOperation {
            self.errorMessage = GSConnectionErrorMessage(title: title, message: message)
        }
    }
    
    private func connectionFailed() {
        errorOccurred(title: "Connect Error", message: "Failed to connect to \(destination)")
        changeState(newState:.disconnected)
    }
    
    private func connectionSuccessful()
    {
        changeState(newState:.connected)
        logger.debug("Connected to \(self.destination)")
    }
    
    private func doConnect() {
        logger.debug("Attempting to connect to \(self.destination)")
        client = TCPClient(address: destination, port: Int32(port))
        guard let client = client else {
            OperationQueue.main.addOperation { self.connectionFailed() }
            return
        }
        switch client.connect(timeout: 10) {
        case .success:
            OperationQueue.main.addOperation { self.connectionSuccessful() }
        case .failure(let error):
            client.close()
            self.client = nil
            logger.error("Failed to connect to \(self.destination): \(String(describing: error))")
            OperationQueue.main.addOperation { self.connectionFailed() }
            return
        }
        
        while (true) {
            guard let byteArray = client.read(2) else {
                break
            }
            let data = Data(byteArray)
            do {
                let unpacked = try unpack("<h", data)
                if (unpacked[0] as? Int == LISTEN_SEND_MORE) {
                    condition.lock()
                    canSend = true
                    condition.broadcast()
                    condition.unlock()
                } else {
                    logger.error("Unexpected message on socket from \(self.destination)")
                    errorOccurred(title: "Protocol Error", message: "Unexpected message from the GS")
                    break
                }
            }
            catch {
                logger.error("Unable to unpack message on socket from \(self.destination)")
                errorOccurred(title: "Protocol Error", message: "Unexpected message from the GS")
                break
            }
        }
        
        client.close()
        self.client = nil
        OperationQueue.main.addOperation { self.disconnect() }
    }
    
    func connect(destination : String) {
        self.destination = destination
        changeState(newState: .connecting)
        readQueue.addOperation {
            self.doConnect()
        }
    }
    
    deinit {
        disconnect()
    }
    
    func disconnect() {
        if (state == .listening) {
            stopListening()
        }
        
        condition.lock()
        if (client != nil) {
            client!.close()
            self.client = nil
        }
        condition.broadcast()
        condition.unlock()
        self.changeState(newState:.disconnected)
    }
    
    func stopListening() {
        logger.debug("Stopped listening")
        if let speechForwarder = speechForwarder {
            speechForwarder.stopListening()
            self.speechForwarder = nil
        }
        condition.lock()
        if (state == .listening) {
            changeState(newState: .stoplistening)
            condition.broadcast()
        }
        condition.unlock()
    }
    
    private func sendListenMsg(isListening: Bool) -> Bool {
        guard let client = client else { return false }
        
        switch (client.send(data: pack("<hh", [LISTEN_STATE_MSG, isListening ? 1 : 0]))) {
        case .success:
            break
        case .failure(let error):
            self.logger.error("Unable to send header: \(String(describing: error))")
            return false
        }
        
        return true
    }
    
    func listen(speechForwarder: SpeechForwarderProtocol) {
        textHeard = ""
        writeQueue.addOperation {
            if (!self.sendListenMsg(isListening: true)) {
                self.errorOccurred(title: "Write Error", message: "Unable to send data to the GS")
                return
            }
            
            OperationQueue.main.addOperation {
                self.changeState(newState: .listening)
                if (!speechForwarder.startListening()) {
                    self.logger.error("Unable to start listening")
                    self.errorOccurred(title: "Speech Error", message: "Unable to start listening for speech")
                    self.stopListening()
                    return
                }
                self.speechForwarder = speechForwarder
            }
            
            self.send()
            
            _ = self.sendListenMsg(isListening: false)
            
            OperationQueue.main.addOperation {
                if (self.state == .stoplistening) {
                    self.changeState(newState: .connected)
                }
            }
        }
    }
    
    func set(text:String)
    {
        condition.lock()
        textHeard = text
        condition.broadcast()
        condition.unlock()
    }

    private func send() {
        var stringLastSent = ""
        var stringToSend = ""
        
        while true {
            condition.lock()
            guard client != nil else {
                condition.unlock()
                return
            }
            if ((stringLastSent == textHeard) && (state == .stoplistening)) {
                condition.unlock()
                return
            }
            if ((!canSend) ||
                (stringLastSent == textHeard)) {
                condition.wait()
                condition.unlock()
                continue
            }
            stringToSend = textHeard
            condition.unlock()
            
            if send(latestText: stringToSend, lastSent: stringLastSent) {
                stringLastSent = stringToSend
                condition.lock()
                canSend = false
                condition.unlock()
            }
        }
    }
    
    private func send(latestText : String, lastSent: String) -> Bool {
        guard let client = client else { return false }
        var commonChars = lastSent.count
        while (commonChars > 0) {
            if (latestText.prefix(commonChars) ==  lastSent.prefix(commonChars)) {
                break
            }
            commonChars -= 1
        }
        var stringToSend = ""
        if (commonChars < lastSent.count) {
            stringToSend = String(repeating: "\u{7f}", count: lastSent.count - commonChars)
        }
        stringToSend.append(contentsOf: latestText.suffix(latestText.count - commonChars).replacingOccurrences(of: "\n", with: "\r"))
        
        if (stringToSend.count == 0) {
            return false
        }
    
        // JSR_TODO - Handle strings to send that are longer than 64K (doubt that would happen though)
        let nsEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringBuiltInEncodings.macRoman.rawValue))
        let encoding = String.Encoding(rawValue: nsEnc) // String.Encoding
        if let bytes = stringToSend.data(using: encoding) {
            switch (client.send(data: pack("<hh", [LISTEN_TEXT_MSG, bytes.count]))) {
            case .success:
                switch (client.send(data: bytes)) {
                case .success:
                    logger.debug("Sent text \"\(stringToSend)\"")
                    break
                case .failure(let error):
                    OperationQueue.main.addOperation {
                        self.errorOccurred(title: "Write Error", message: "Unable to send text to the GS")
                        self.stopListening()
                    }
                    logger.error("Failed to send text: \(String(describing: error))")
                    return false
                }
            case .failure(let error):
                OperationQueue.main.addOperation {
                    self.errorOccurred(title: "Write Error", message: "Unable to send text to the GS")
                    self.stopListening()
                }
                logger.error("Failed to send text: \(String(describing: error))")
            }
        }
        return true
    }
}


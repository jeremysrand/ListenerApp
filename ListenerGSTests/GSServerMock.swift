//
//  GSServerMock.swift
//  ListenerGSTests
//
//  Created by Jeremy Rand on 2022-03-16.
//

import Foundation
@testable import ListenerGS

class GSServerMock {
    private let server = TCPServer(address: "127.0.0.1", port: Int32(GSConnection.port))
    private var client : TCPClient?
    
    deinit {
        server.close()
        disconnect()
    }
    
    func accept() -> Bool {
        let result = server.listen()
        if (!result.isSuccess) {
            return false
        }
        client = server.accept(timeout: 10)
        return (client != nil)
    }
    
    func hasClient() -> Bool {
        return client != nil
    }
    
    func disconnect() {
        if let client = client {
            client.close()
            self.client = nil
        }
    }
    
    func getListenState(isListening : Bool) -> Bool {
        guard let client = client else { return false }
        guard let byteArray = client.read(4) else {
            return false
        }
        
        if (byteArray.count != 4) {
            return false
        }
        
        let data = Data(byteArray)
        do {
            let unpacked = try unpack("<hh", data)
            if (unpacked[0] as? Int != GSConnection.LISTEN_STATE_MSG) {
                return false
            }
            if (unpacked[1] as? Int != (isListening ? 1 : 0)) {
                return false
            }
            return true
        }
        catch {
            return false
        }
    }
    
    func sendMore() -> Bool {
        guard let client = client else { return false }
        
        let result = client.send(data: pack("<h", [GSConnection.LISTEN_SEND_MORE]))
        return result.isSuccess
    }
    
    func sendMoreBad() -> Bool {
        guard let client = client else { return false }
        
        let result = client.send(data: pack("<h", [6502]))
        return result.isSuccess
    }
    
    func getText() -> String {
        guard let client = client else { return "" }
        
        guard let headerByteArray = client.read(4) else {
            return ""
        }
        
        if (headerByteArray.count != 4) {
            return ""
        }
        
        let headerData = Data(headerByteArray)
        var textLength = 0
        do {
            let unpacked = try unpack("<hh", headerData)
            if (unpacked[0] as? Int != GSConnection.LISTEN_TEXT_MSG) {
                return ""
            }
            textLength = unpacked[1] as! Int
        }
        catch {
            return ""
        }
        
        if (textLength == 0) {
            return ""
        }
        
        guard let bodyByteArray = client.read(textLength) else {
            return ""
        }
        
        if (bodyByteArray.count != textLength) {
            return ""
        }
        
        let bodyData = Data(bodyByteArray)
        let nsEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringBuiltInEncodings.macRoman.rawValue))
        let encoding = String.Encoding(rawValue: nsEnc) // String.Encoding
        let result = String(data:bodyData, encoding: encoding)
        guard let result = result else { return "" }
        return result
    }
    
    func getDisconnect() -> Bool {
        guard let client = client else { return false }
        
        guard let headerByteArray = client.read(1) else {
            return true
        }
        
        return (headerByteArray.count == 0)
    }
}

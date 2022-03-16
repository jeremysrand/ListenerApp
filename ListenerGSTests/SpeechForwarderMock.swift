//
//  SpeechForwarderMock.swift
//  ListenerGSTests
//
//  Created by Jeremy Rand on 2022-03-16.
//

import Foundation
@testable import ListenerGS

class SpeechForwarderMock : SpeechForwarderProtocol {
    var isListening = false
    var startListeningResult = true
    
    func startListening(connection: GSConnection) -> Bool {
        isListening = startListeningResult
        return startListeningResult
    }
    
    func stopListening() {
        assert(isListening)
        isListening = false
    }
    
}

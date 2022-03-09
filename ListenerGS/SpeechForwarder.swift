//
//  SpeechForwarder.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-10-18.
//

import Foundation
import os
import Speech

class SpeechForwarder : ObservableObject {
    @Published var listening = false
    @Published var connected = false
    @Published var connecting = false
    @Published var textHeard = ""
    @Published var sending = false
    
    let LISTEN_STATE_MSG = 1
    let LISTEN_TEXT_MSG = 2
    let LISTEN_SEND_MORE = 3
    
    let port = 19026
    private var client: TCPClient?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages[0]))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private let logger = Logger()
    
    private let queue = OperationQueue()
    
    private var condition = NSCondition()
    private var latestText = ""
    
    func connect(destination : String) {
        connecting = true
        queue.addOperation {
            self.logger.debug("Attempting to connect to \(destination)")
            self.client = TCPClient(address: destination, port: Int32(self.port))
            guard let client = self.client else {
                OperationQueue.main.addOperation { self.connecting = false }
                return
            }
            switch client.connect(timeout: 10) {
            case .success:
                OperationQueue.main.addOperation { self.connected = true }
                self.logger.debug("Connected to \(destination)")
            case .failure(let error):
                client.close()
                self.client = nil
                self.logger.error("Failed to connect to \(destination): \(String(describing: error))")
                break
            }
            OperationQueue.main.addOperation { self.connecting = false }
        }
    }
    
    func disconnect() {
        if (listening) {
            listen()
        }
        
        guard let client = client else { return }
        
        condition.lock()
        client.close()
        self.client = nil
        condition.broadcast()
        condition.unlock()
        
        connected = false
    }
    
    func listen() {
        self.listening.toggle()
        if (self.listening) {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                // The authorization status results in changes to the
                // app’s interface, so process the results on the app’s
                // main queue.
                OperationQueue.main.addOperation {
                    switch authStatus {
                        case .authorized:
                            break
                            
                        case .denied:
                            self.listening = false
                            break

                        case .restricted:
                            self.listening = false
                            break

                        case .notDetermined:
                            self.listening = false
                            break
                            
                        default:
                            self.listening = false
                            break
                    }
                }
            }
        }
        
        guard let client = client else { return }
        if (self.listening) {
            switch (client.send(data: isListening())) {
                case .success:
                    break
                case .failure(let error):
                    self.listening = false
                    logger.error("Unable to send header: \(String(describing: error))")
            }
        }
        
        if (self.listening) {
            do {
                try startRecording()
                logger.debug("Started listening")
            }
            catch {
                self.listening = false
            }
        }
        
        if (!self.listening) {
            logger.debug("Stopped listening")
            recognitionRequest?.endAudio()
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionTask?.cancel()

            self.recognitionRequest = nil
            self.recognitionTask = nil
            condition.lock()
            self.listening = false
            condition.broadcast()
            condition.unlock()
            switch (client.send(data: isListening())) {
                case .success:
                    break
                case .failure(let error):
                    logger.error("Failed to send header: \(String(describing: error))")
            }
        }
    }
    
    private func isListening() -> Data {
        return pack("<hh", [LISTEN_STATE_MSG, listening ? 1 : 0])
    }

    private func send() {
        var stringLastSent = ""
        var stringToSend = ""
        var canSend = true
        
        while true {
            while (!canSend) {
                logger.debug("Cannot send")
                guard let client = client else {
                    logger.debug("Returning because client gone")
                    return
                }
                guard let byteArray = client.read(2, timeout: 1) else {
                    logger.debug("Did not read data")
                    continue
                }
                let data = Data(byteArray)
                do {
                    let unpacked = try unpack("<h", data)
                    canSend = (unpacked[0] as? Int == LISTEN_SEND_MORE)
                    logger.debug("Updated canSend")
                }
                catch {
                    logger.debug("Unpack failed")
                    continue
                }
            }
            logger.debug("Can send")
            
            condition.lock()
            while (stringLastSent == latestText) {
                if (!self.listening) {
                    condition.unlock()
                    return
                }
                condition.wait()
                if (!self.listening) {
                    condition.unlock()
                    return
                }
                guard client != nil else {
                    condition.unlock()
                    return
                }
            }
            stringToSend = latestText
            condition.unlock()
            
            if send(latestText: stringToSend, lastSent: stringLastSent) {
                stringLastSent = stringToSend
                canSend = false
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
                                if (self.listening) {
                                    self.listen()
                                }
                            }
                            logger.error("Failed to send text: \(String(describing: error))")
                            return false
                    }
                case .failure(let error):
                    OperationQueue.main.addOperation {
                        if (self.listening) {
                            self.listen()
                        }
                    }
                    logger.error("Failed to send text: \(String(describing: error))")
            }
        }
        return true
    }
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        self.textHeard = ""
        self.latestText = ""
        self.sending = true
        
        queue.addOperation {
            self.send()
            OperationQueue.main.addOperation { self.sending = false }
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.condition.lock()
                self.latestText = result.bestTranscription.formattedString
                self.condition.broadcast()
                self.condition.unlock()
                
                OperationQueue.main.addOperation { self.textHeard = result.bestTranscription.formattedString }
                
                isFinal = result.isFinal
            }
            
            if error != nil {
                self.logger.error("Error from recognizer: \(String(describing: error))")
            }
            
            if error != nil || isFinal {
                OperationQueue.main.addOperation {
                    if (self.listening) {
                        self.listen()
                    }
                }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}


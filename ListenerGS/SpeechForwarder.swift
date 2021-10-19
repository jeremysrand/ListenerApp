//
//  SpeechForwarder.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-10-18.
//

import Foundation

import Speech

class SpeechForwarder : ObservableObject {
    @Published var listening = false
    @Published var listenEnabled = false
    @Published var log = ""
    @Published var ipAddress = ""
    private var textHeard = ""
    @Published var isEditing = false
    
    let LISTEN_STATE_MSG = 1
    let LISTEN_TEXT_MSG = 2
    
    let port = 19026
    private var client: TCPClient?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    func logError(message: String) {
        log.append("ERROR: " + message + "\n")
    }
    
    func logEvent(message: String) {
        log.append("EVENT: " + message + "\n")
    }
    
    func validate(destination : String) {
        logEvent(message: "Attempting to connect to " + destination)
        client = TCPClient(address: destination, port: Int32(port))
        guard let client = client else { return }
        switch client.connect(timeout: 10) {
        case .success:
            listenEnabled = true
            logEvent(message: "Connected to " + destination)
        case .failure(let error):
            client.close()
            self.client = nil
            logError(message: String(describing: error))
            break
        }
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
                    logError(message: String(describing: error))
            }
        }
        
        if (self.listening) {
            do {
                try startRecording()
                logEvent(message: "Listening...")
            }
            catch {
                self.listening = false
            }
        }
        
        if (!self.listening) {
            logEvent(message: "Listening stopped")
            audioEngine.stop()
            recognitionRequest?.endAudio()
            switch (client.send(data: isListening())) {
                case .success:
                    break
                case .failure(let error):
                    self.listening = false
                    logError(message: String(describing: error))
            }
        }
    }
    
    private func isListening() -> Data {
        return pack("<hh", [LISTEN_STATE_MSG, listening ? 1 : 0])
    }

    private func send(latestText : String) {
        guard let client = client else { return }
        var commonChars = self.textHeard.count
        while (commonChars > 0) {
            if (latestText.prefix(commonChars) ==  self.textHeard.prefix(commonChars)) {
                break
            }
            commonChars -= 1
        }
        var stringToSend = ""
        if (commonChars < self.textHeard.count) {
            stringToSend = String(repeating: "\u{7f}", count: self.textHeard.count - commonChars)
        }
        stringToSend.append(contentsOf: latestText.suffix(latestText.count - commonChars).replacingOccurrences(of: "\n", with: "\r"))
        
        if (stringToSend.count > 0) {
            // TODO - Handle strings to send that are longer than 64K (doubt that would happen though)
            // TODO - Try to convert encoding from utf8 to something the GS can understand.
            switch (client.send(data: pack("<hh\(stringToSend.count)s", [LISTEN_TEXT_MSG, stringToSend.count, stringToSend]))) {
                case .success:
                    self.textHeard = latestText
                    logEvent(message: "Sent \"" + stringToSend + "\"")
                    break
                case .failure(let error):
                    self.listening = false
                    logError(message: String(describing: error))
            }
        }
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

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        self.textHeard = ""
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.send(latestText: result.bestTranscription.formattedString)
                isFinal = result.isFinal
                print("Text \(result.bestTranscription.formattedString)")
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.listening = false
                self.logEvent(message: "Listening stopped")
                guard let client = self.client else { return }
                client.send(data: self.isListening())
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}


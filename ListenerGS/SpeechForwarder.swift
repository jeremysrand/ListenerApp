//
//  SpeechForwarder.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-10-18.
//

import Foundation
import os
import Speech

class SpeechForwarder : SpeechForwarderProtocol {
    
    private var connection : GSConnection
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages[0]))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private let logger = Logger()
    
    init(connection : GSConnection) {
        self.connection = connection
    }
    
    func startListening() -> Bool {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    break
                        
                case .denied, .restricted, .notDetermined:
                    self.connection.stopListening()
                    
                default:
                    self.connection.stopListening()
                }
            }
        }
            
        do {
            try startRecording()
            logger.debug("Started listening")
        }
        catch {
            return false
        }
        return true
    }
    
    func stopListening() {
        logger.debug("Stopped listening")
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
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
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                OperationQueue.main.addOperation { self.connection.set(text: result.bestTranscription.formattedString) }
                isFinal = result.isFinal
            }
            
            if error != nil {
                self.logger.error("Error from recognizer: \(String(describing: error))")
                self.connection.errorOccurred(title: "Recognizer Error", message: "Speech recognizer failed with an error")
            }
            
            if error != nil || isFinal {
                OperationQueue.main.addOperation {
                    self.connection.stopListening()
                }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}


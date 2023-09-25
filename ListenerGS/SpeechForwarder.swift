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
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages[0]))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private let logger = Logger()
    
    private let audioQueue = DispatchQueue.global()
    
    func startListening(connection : GSConnection) -> Bool {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    break
                        
                case .denied, .restricted, .notDetermined:
                    connection.stopListening()
                    
                default:
                    connection.stopListening()
                }
            }
        }
            
        do {
            try startRecording(connection: connection)
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
        recognitionTask?.finish()

        recognitionRequest = nil
        recognitionTask = nil
    }
    
    private func startRecording(connection : GSConnection) throws {
        
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
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Configure the microphone input.
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let speechFormat = recognitionRequest.nativeAudioFormat
        logger.debug("Recording format \(inputFormat, privacy: .public), speech format \(speechFormat, privacy: .public)")
        var formatConverter: AVAudioConverter?
        if (!inputFormat.isEqual(speechFormat)) {
            formatConverter = AVAudioConverter(from:inputFormat, to: speechFormat)
            formatConverter?.downmix = true
        }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            guard let formatConverter = formatConverter else {
                self.recognitionRequest?.append(buffer)
                return
            }
            // self.recognitionRequest?.append(buffer)
            let pcmBuffer = AVAudioPCMBuffer(pcmFormat: speechFormat, frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * speechFormat.sampleRate / inputFormat.sampleRate))
            var error: NSError? = nil
            
            let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
            }
            
            formatConverter.convert(to: pcmBuffer!, error: &error, withInputFrom: inputBlock)
            
            if error == nil {
                self.recognitionRequest?.append(pcmBuffer!)
            }
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak connection] result, error in
            var isFinal = false
            
            if error != nil {
                self.logger.error("Error from recognizer: \(String(describing: error), privacy:.public)")
            } else if let result = result {
                isFinal = result.isFinal
                if !isFinal || result.bestTranscription.formattedString != "" {
                    // Update the text view with the results.
                    OperationQueue.main.addOperation {
                        guard let connection = connection else { return }
                        connection.set(text: result.bestTranscription.formattedString)
                    }
                }
            }
            
            if error != nil || isFinal {
                OperationQueue.main.addOperation {
                    guard let connection = connection else { return }
                    connection.stopListening()
                }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}


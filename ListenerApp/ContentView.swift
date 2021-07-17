//
//  ContentView.swift
//  ListenerApp
//
//  Created by Jeremy Rand on 2021-07-16.
//

import SwiftUI
import Speech

struct ContentView: View {
    @State private var listening = false
    @State private var listenEnabled = false
    @State private var textHeard = ""
    @State private var ipAddress = ""
    @State private var isEditing = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    var body: some View {
        VStack {
            TextField("IP Address", text: $ipAddress) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                validate(destination: ipAddress)
            }
                .padding()
            Label(textHeard, systemImage:"")
                .labelStyle(TitleOnlyLabelStyle())
                .padding()
            Button("Listen") {
                listen()
            }
            .padding()
            .background(listening ? Color.red : Color.white)
            .foregroundColor(listening ? .black : .blue)
            .disabled(listenEnabled == false)
        }
    }
    
    func validate(destination : String) {
        listenEnabled = true
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
        
        if (self.listening) {
            do {
                try startRecording()
            }
            catch {
                
            }
        } else {
            audioEngine.stop()
            recognitionRequest?.endAudio()
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
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.textHeard = result.bestTranscription.formattedString
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

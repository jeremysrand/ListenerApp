//
//  ContentView.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-07-16.
//

import SwiftUI
import Speech

struct ContentView: View {
    @StateObject private var speechForwarder = SpeechForwarder()
    
    var body: some View {
        VStack {
            TextField("IP Address", text: $speechForwarder.ipAddress) { isEditing in
                speechForwarder.isEditing = isEditing
            } onCommit: {
                speechForwarder.validate(destination: speechForwarder.ipAddress)
            }
                .padding()
            
            ScrollView() {
                Text(speechForwarder.log)
                    .multilineTextAlignment(.leading)
            }
            
            Button("Listen") {
                speechForwarder.listen()
            }
                .padding()
                .background(speechForwarder.listening ? Color.red : Color.clear)
                .foregroundColor(speechForwarder.listening ? .black : .blue)
                .disabled(speechForwarder.listenEnabled == false)
                .frame(maxWidth: .infinity)
                .buttonStyle(PlainButtonStyle())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

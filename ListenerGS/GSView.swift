//
//  GSView.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-12-21.
//

import SwiftUI

struct GSButtonStyle : ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        GSButtonStyleView(configuration: configuration)
    }
}

private extension GSButtonStyle {
    struct GSButtonStyleView: View {
        // tracks if the button is enabled or not
        @Environment(\.isEnabled) var isEnabled
        @Environment(\.colorScheme) var colorScheme
        // tracks the pressed state
        let configuration: GSButtonStyle.Configuration
        
        var body: some View {
            return configuration.label
                .lineLimit(nil)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? Color("ButtonColor") : Color("InactiveButtonColor"))
                .foregroundColor(isEnabled ? Color("ButtonTextColor") : Color("InactiveButtonTextColor"))
                .font(.subheadline)
                .clipShape(Capsule())
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        }
    }
}

struct GSView: View {
    private let ipAddress : String
    @StateObject private var speechForwarder = SpeechForwarder()
    
    var body: some View {
        VStack {
            VStack {
                Button(speechForwarder.connected ?
                       "\(Image(systemName: "desktopcomputer.trianglebadge.exclamationmark"))  Disconnect from \(ipAddress)" :
                       "\(Image(systemName: "desktopcomputer.and.arrow.down"))  Connect to \(ipAddress)") {
                    if (speechForwarder.connected) {
                        speechForwarder.disconnect()
                    } else {
                        speechForwarder.connect(destination: ipAddress)
                    }
                }
                .disabled(false)
                .buttonStyle(GSButtonStyle())
                
                Button(speechForwarder.listening ?
                       "\(Image(systemName: "ear.trianglebadge.exclamationmark"))  Stop Listening" :
                       "\(Image(systemName: "ear.and.waveform"))  Listen and Send Text") {
                    speechForwarder.listen()
                }
                .disabled(!speechForwarder.connected)
                .buttonStyle(GSButtonStyle())
            }
            .fixedSize(horizontal: true, vertical: false)
            .navigationBarTitle(ipAddress)
        }
        
        Text(speechForwarder.textHeard)
            .truncationMode(.head)
            .lineLimit(15)
            .padding()
        
        Spacer()
    }
    
    init(ipAddress : String) {
        self.ipAddress = ipAddress
    }
}

struct GSView_Previews: PreviewProvider {
    static var previews: some View {
        GSView(ipAddress: "192.168.1.1")
    }
}

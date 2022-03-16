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
    @StateObject private var connection = GSConnection()
    
    var body: some View {
        VStack {
            VStack {
                switch (connection.state) {
                case .disconnected:
                    Button("\(Image(systemName: "desktopcomputer.and.arrow.down"))  Connect to \(ipAddress)") {
                        connection.connect(destination: ipAddress)
                    }
                    .buttonStyle(GSButtonStyle())
                    
                case .connecting:
                    Button("\(Image(systemName: "desktopcomputer.and.arrow.down"))  Connecting to \(ipAddress)") {
                    }
                    .disabled(true)
                    .buttonStyle(GSButtonStyle())
                    
                case .connected, .listening, .stoplistening:
                    Button("\(Image(systemName: "desktopcomputer.trianglebadge.exclamationmark"))  Disconnect from \(ipAddress)") {
                        connection.disconnect()
                    }
                    .disabled(connection.state != .connected)
                    .buttonStyle(GSButtonStyle())
                }
                
                switch (connection.state)
                {
                case .disconnected, .stoplistening, .connecting:
                    Button("\(Image(systemName: "ear.and.waveform"))  Listen and Send Text") {
                    }
                    .disabled(true)
                    .buttonStyle(GSButtonStyle())
                    
                case .connected:
                    Button("\(Image(systemName: "ear.and.waveform"))  Listen and Send Text") {
                        connection.listen(speechForwarder: SpeechForwarder())
                    }
                    .buttonStyle(GSButtonStyle())
                    
                case .listening:
                    Button("\(Image(systemName: "ear.trianglebadge.exclamationmark"))  Stop Listening") {
                        connection.stopListening()
                    }
                    .buttonStyle(GSButtonStyle())
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .navigationBarTitle(ipAddress)
        }
        .alert(item: $connection.errorMessage) { errorMessage in
            Alert(title:Text(errorMessage.title), message: Text(errorMessage.message))
        }
        
        Text(connection.textHeard)
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

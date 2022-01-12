//
//  GSView.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-12-21.
//

import SwiftUI

extension Color {
  static let defaultBlue = Color(red: 0, green: 97 / 255.0, blue: 205 / 255.0)
  static let paleBlue = Color(red: 188 / 255.0, green: 224 / 255.0, blue: 253 / 255.0)
  static let paleWhite = Color(white: 1, opacity: 179 / 255.0)
}

struct GSButtonStyle : ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        GSButtonStyleView(configuration: configuration)
    }
}

private extension GSButtonStyle {
    struct GSButtonStyleView: View {
        // tracks if the button is enabled or not
        @Environment(\.isEnabled) var isEnabled
        // tracks the pressed state
        let configuration: GSButtonStyle.Configuration
        
        var body: some View {
            return configuration.label
                .lineLimit(nil)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? Color.defaultBlue : Color.paleBlue)
                .foregroundColor(isEnabled ? .white : .paleWhite)
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
            
            Spacer()
        }
        .fixedSize(horizontal: true, vertical: false)
        .navigationBarTitle(ipAddress)
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

//
//  GSView.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-12-21.
//

import SwiftUI

struct GSView: View {
    private let ipAddress : String
    
    var body: some View {
        Text(ipAddress)
        Button("Connect to \(ipAddress)") {
            
        }
        .padding()
        .background(Color(red: 0, green: 0, blue: 0.5))
        .foregroundColor(.white)
        .clipShape(Capsule())
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

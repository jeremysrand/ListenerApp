//
//  ListenerGSApp.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-07-16.
//

import SwiftUI

@main
struct ListenerGSApp: App {
    @StateObject private var destinations = GSDestinations()
    
    var body: some Scene {
        WindowGroup {
            // ContentView(destinations: destinations)
            // ContentView()
            MainView()
        }
    }
}

//
//  GSDestinations.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-10-19.
//

import Foundation


struct Destination: Identifiable, Hashable {
    let ipAddress : String
    let id = UUID()
}

class GSDestinations : ObservableObject {
    @Published var dests:[Destination] = []
    
    private var storedDestinations : [Any] = []
    
    static let kDestinationKey = "destinations"
    static let kDestinationIpAddress = "ip_address"
    
    public func onDelete(offsets: IndexSet) {
        dests.remove(atOffsets: offsets)
        storedDestinations.remove(atOffsets: offsets)
        saveDestinations()
    }
    
    public func onMove(source: IndexSet, destination: Int) {
        dests.move(fromOffsets: source, toOffset: destination)
        storedDestinations.move(fromOffsets: source, toOffset: destination)
        saveDestinations()
    }
    
    public func onAdd(ipAddress: String) {
        dests.append(Destination(ipAddress: ipAddress))
        storedDestinations.append([GSDestinations.kDestinationIpAddress : ipAddress])
        saveDestinations()
    }
    
    private func loadDestinations() {
        if let newStoredDestinations = NSUbiquitousKeyValueStore.default.array(forKey: GSDestinations.kDestinationKey) {
            storedDestinations = newStoredDestinations
            dests = []
            
            for value in storedDestinations {
                if let ipAddress = (value as! [String:String])[GSDestinations.kDestinationIpAddress] {
                    dests.append(Destination(ipAddress: ipAddress))
                } else {
                    storedDestinations = []
                    dests = []
                    break
                }
            }
        } else {
            storedDestinations = []
            dests = []
        }
    }
    
    private func saveDestinations() {
        NSUbiquitousKeyValueStore.default.set(storedDestinations, forKey: GSDestinations.kDestinationKey)
    }
    
    init() {
        loadDestinations()
        
        // JSR_TODO - Add code here to watch for changes from iCloud
    }
}

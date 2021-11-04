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
    
    public func onDelete(offsets: IndexSet) {
        dests.remove(atOffsets: offsets)
    }
    
    public func onMove(source: IndexSet, destination: Int) {
        dests.move(fromOffsets: source, toOffset: destination)
    }
    
    public func onAdd(ipAddress: String) {
        dests.append(Destination(ipAddress: ipAddress))
    }
}

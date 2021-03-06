//
//  GSDestinations.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-10-19.
//

import Foundation


struct Destination: Identifiable, Hashable {
    let ipAddress : String
    let id : UUID
    
    init(ipAddress: String)
    {
        self.ipAddress = ipAddress
        self.id = UUID()
    }
    
    init(ipAddress: String, uuid: String)
    {
        self.ipAddress = ipAddress
        let idMaybe = UUID(uuidString: uuid)
        if let id = idMaybe {
            self.id = id
        } else {
            self.id = UUID()
        }
    }
}

class GSDestinations : ObservableObject {
    @Published var dests:[Destination] = []
    
    private var storedDestinations : [Any] = []
    
    static let kDestinationKey = "destinations"
    static let kDestinationIpAddress = "ip_address"
    static let kDestinationUUID = "uuid"
    
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
        let newDestination = Destination(ipAddress: ipAddress)
        dests.append(newDestination)
        storedDestinations.append([GSDestinations.kDestinationIpAddress : ipAddress, GSDestinations.kDestinationUUID : newDestination.id.uuidString])
        saveDestinations()
    }
    
    private func loadDestinations() {
        if let newStoredDestinations = NSUbiquitousKeyValueStore.default.array(forKey: GSDestinations.kDestinationKey) {
            storedDestinations = newStoredDestinations
            dests = []
            
            for value in storedDestinations {
                if let ipAddress = (value as! [String:String])[GSDestinations.kDestinationIpAddress] {
                    if let id = (value as! [String:String])[GSDestinations.kDestinationUUID] {
                        dests.append(Destination(ipAddress: ipAddress, uuid: id))
                    } else {
                        dests.append(Destination(ipAddress: ipAddress))
                    }
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
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    @objc func onUbiquitousKeyValueStoreDidChangeExternally(notification:Notification)
    {
        // It would be nice to do something better than just replacing dests with what we get from iCloud.
        // I think when we do this, the entire list will be rebuilt and anything selected is probably lost.
        // The list isn't likely to change and will also be small so maybe it isn't too big of a deal.
        loadDestinations()
    }
    
    init() {
        loadDestinations()
        NotificationCenter.default.addObserver(self, selector: #selector(onUbiquitousKeyValueStoreDidChangeExternally(notification:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

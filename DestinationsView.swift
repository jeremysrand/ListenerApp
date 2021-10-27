//
//  DestinationsView.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-10-26.
//

import SwiftUI

struct Destination: Identifiable, Hashable {
    let ipAddress : String
    let id = UUID()
}

struct DestinationsView: View {
    @State private var destinations = [
        Destination(ipAddress: "192.168.1.20"),
        Destination(ipAddress: "192.168.1.21")
    ]
    @State private var editMode = EditMode.inactive
    
    var body: some View {
        List {
            ForEach(destinations) { destination in
                NavigationLink(destination: Text(destination.ipAddress)) {
                    Text(destination.ipAddress)
                }
            }
            .onDelete(perform: onDelete)
            .onMove(perform: onMove)
        }
        .navigationBarTitle("GS Destinations")
        .navigationBarItems(leading: EditButton(), trailing: addButton)
        .environment(\.editMode, $editMode)
    }
    
    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(Button(action: onAdd) { Image(systemName: "plus") })
        default:
            return AnyView(EmptyView())
        }
    }
    
    private func onDelete(offsets: IndexSet) {
        destinations.remove(atOffsets: offsets)
    }

    private func onMove(source: IndexSet, destination: Int) {
        destinations.move(fromOffsets: source, toOffset: destination)
    }
    
    func onAdd() {
        destinations.append(Destination(ipAddress: "192.168.1.22"))
    }
}

struct DestinationsView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationsView()
    }
}

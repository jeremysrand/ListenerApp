//
//  DestinationsView.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-10-26.
//

import SwiftUI

struct SheetView : View {
    @State private var destination = ""
    @Binding var showSheet: Bool
    var destinations : GSDestinations
    
    var body: some View {
        VStack {
            Text("Enter the hostname or IP address of your GS:")
                .font(.title2)
            TextField("New destination", text: self.$destination) { isEditing in
            } onCommit: {
                self.showSheet = false
                onAdd()
            }
            .padding()
            HStack {
                Button("Cancel") {
                    self.showSheet = false
                }
                .padding()
                Button("Add") {
                    self.showSheet = false
                    onAdd()
                }
                .padding()
            }
        }.padding()
    }
    
    func onAdd() {
        let newDestination = destination
        destination = ""
        // This schedules the add of the destination for 0.1 s from now.  Under iOS 14.x, it seems like there is
        // a bug such that if I synchronously add the destination here, the popup will not dismiss.  Some kind of
        // swiftui bug I think.  No issue in iOS 15 as far as I can tell.  So, this queuing of the add is only
        // necessary as a workaround.
        OperationQueue.main.schedule(after: OperationQueue.SchedulerTimeType(Date(timeIntervalSinceNow: 0.1))) {
            destinations.onAdd(ipAddress: newDestination)
        }
    }
}

struct DestinationsView: View {
    @State private var editMode = EditMode.inactive
    @State private var showSheet = false
    @State private var newDestination = ""
    
    @StateObject private var destinations = GSDestinations()
    
    var body: some View {
        List {
            ForEach(destinations.dests) { destination in
                NavigationLink(destination: GSView(ipAddress: destination.ipAddress)) {
                    Text(destination.ipAddress)
                }
            }
            .onDelete(perform: onDelete)
            .onMove(perform: onMove)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: toggleEdit) {
                    Text(editMode == .active ? "Done" : "Edit")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                addButton
            }
        }
        .navigationBarTitle("GS Destinations")
        .environment(\.editMode, $editMode)
    }
    
    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(Button(action: showAdd) { Image(systemName: "plus") }
                .sheet(isPresented: self.$showSheet) {
                    SheetView(showSheet: self.$showSheet, destinations: destinations)
                })
        default:
            return AnyView(EmptyView())
        }
    }
    
    private func onDelete(offsets: IndexSet) {
        destinations.onDelete(offsets: offsets)
    }

    private func onMove(source: IndexSet, destination: Int) {
        destinations.onMove(source: source, destination: destination)
    }
    
    func toggleEdit() {
        editMode = (editMode == .active ? .inactive : .active)
    }
    
    func showAdd() {
        self.showSheet = true;
    }
}

struct DestinationsView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationsView()
    }
}


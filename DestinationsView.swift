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
    @State private var destinations:[Destination] = []
    @State private var editMode = EditMode.inactive
    @State private var showPopover = false
    @State private var newDestination = ""
    
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
            return AnyView(Button(action: showAdd) { Image(systemName: "plus") }
                            .popover(
                                isPresented: self.$showPopover,
                                arrowEdge: .bottom
                            ) { addPopover } )
        default:
            return AnyView(EmptyView())
        }
    }
    
    private var addPopover: some View {
        VStack {
            Text("Enter the hostname or IP address of your GS:")
                .font(.title2)
            TextField("New destination", text: self.$newDestination) { isEditing in
            } onCommit: {
                onAdd()
            }
            .padding()
            HStack {
                Button("Cancel") {
                    self.showPopover = false
                    editMode = EditMode.inactive
                }
                .padding()
                Button("Add") {
                    onAdd()
                }
                .padding()
            }
        }.padding()
    }
    
    private func onDelete(offsets: IndexSet) {
        destinations.remove(atOffsets: offsets)
    }

    private func onMove(source: IndexSet, destination: Int) {
        destinations.move(fromOffsets: source, toOffset: destination)
    }
    
    func showAdd() {
        self.showPopover = true;
    }
    
    func onAdd() {
        destinations.append(Destination(ipAddress: self.newDestination))
        newDestination = ""
        showPopover = false;
    }
}

struct DestinationsView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationsView()
    }
}

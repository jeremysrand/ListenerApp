//
//  MainView.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2021-10-26.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            DestinationsView()
            EmptyView() // JSR_TODO - Maybe display some instructions here.
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView()
        }
    }
}

//
//  ListenerInfoView.swift
//  ListenerGS
//
//  Created by Jeremy Rand on 2022-03-16.
//

import SwiftUI

struct ListenerInfoView: View {
    var body: some View {
        ScrollView {
            RichText(html:
"""
<html>
<body>

<p>
ListenerGS allows you to use your modern device as a speech recognition peripheral for a network capable
Apple IIGS.  For more information about how to use the app and links to the software you need to download
to your GS, please visit <a href="https://www.rand-emonium.com/listenergs/">https://www.rand-emonium.com/listenergs/</a>.
</p>

<p>
Once you have the software installed and configured on your Apple IIGS, you should launch an desktop application
that accepts text.  The Teach application is an example of an application that would work.  Make sure there is a
window open which you can type into and then open the Listener NDA from under the Apple menu.  The Listener NDA window
will say it is waiting for a connection.
</p>

<p>
In this app, tap the "+" button and enter the IP address or hostname of your Apple IIGS.  You can enter multiple IP
addresses and hostnames if you have multiple machines.  Your destinations are synced through iCloud so if you have
multiple modern devices, you should find the IP addresses are mirrored to those other devices.
</p>

<p>Select one of these destinations and tap the "Connect" button to bring up a network connection to your Apple IIGS.
On the GS, you should find the NDA window also indicates that the connection is up.  Then tap the "Listen and Send Text"
button.  Speak clearly and you should find that your words are typed into the window on your GS.  If the NDA window was
top-most when you started speaking, you should find that it goes to the back.</p>

<p>
Top "Stop Listening" when you want to stop entering text through speech and "Disconnect" when you are done using the app.
</p>

</body>
</html>
""")
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .navigationBarTitle("Welcome to ListenerGS!")
    }
}

struct ListenerInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ListenerInfoView()
    }
}

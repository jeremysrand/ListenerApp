#  ListenerGS

This is an iOS/iPadOS/macOS app that connects to an Apple IIgs over a network and streams text to it from voice dicatation.  It communicates to the [Listen NDA](https://github.com/jeremysrand/Listener) which must be running on your network capable Apple IIgs.  See that other project for more details about how to use this app.

## Obtaining a Copy

The app is now [available from the AppStore](https://apps.apple.com/us/app/listenergs/id1613273510?itsct=apps_box_badge&itscg=30200).  Also, you can find [zip archive of the macOS version](https://github.com/jeremysrand/ListenerApp/releases/download/v1.0/ListenerGS.zip) if you prefer to get your Mac software outside of the store.  You should also visit [rand-emonium.com](https://www.rand-emonium.com/listenergs/) to get links to the software for your Apple IIGS and information about using it.

## Some Technical Details

It relies on the [Speech Framework](https://developer.apple.com/documentation/speech) built into recent versions of iOS.

This app uses:
* [SwiftSocket v2.1.0](https://github.com/swiftsocket/SwiftSocket/tree/2.1.0) for opening the TCP connection to the Apple IIgs.
* [BinUtils](https://github.com/nst/BinUtils) for packing/unpacking structures on the TCP connection.
* [RichText v1.7.0](https://github.com/NuPlay/RichText/releases/tag/1.7.0) for displaying a nice startup screen on iPad and macOS.

## Warning

This is my first from scratch application in Swift and in SwiftUI and it shows.  I know this code is crufty and bad, even as an inexperienced Swift coder.  It was created as part of the KansasFest 2021 HackFest contest so I only had so much time for code cleanup.  Since then, I have done a bunch of cleanup and things are better.  But I am still not happy with how the code handles the network reads and writes.  A producer/consumer approach where the speech recognizer produces text and the network code consumes that text would be better.  But Apple just changed the multithreading approach in Swift this past year and I am not sure the best way to structure that.  Be patient as this old dog tries to learn some new tricks.

#  ListenerApp

This is an iOS app that connects to an Apple IIgs over a network and streams text to it from voice dicatation.  It communicates to the [Listen NDA](https://github.com/jeremysrand/Listener) which must be running on your network capable Apple IIgs.  See that other project for more details about how to use this app.

## Obtaining a Copy

I am not sure about distribution of this app yet.  I will probably attempt to have it approved for distribution on the AppStore but there is a chance (maybe a good chance) that it will not be allowed.  I believe this code should also work as a Mac application and that platform does allow distribution ouotside of the Mac AppStore so that is a fallback strategy.  But I think using the iPhone as a voice accessory to your Apple IIgs is the best solution so I would like it on iOS.  The code is here so if you have Xcode, you can build this and install it on your own devices I think.  More information to come.

## Some Technical Details

It relies on the [Speech Framework](https://developer.apple.com/documentation/speech) built into recent versions of iOS.

This app uses [SwiftSocket v2.1.0](https://github.com/swiftsocket/SwiftSocket/tree/2.1.0) for opening the TCP connection to the Apple IIgs.
It also uses [BinUtils](https://github.com/nst/BinUtils) for packing/unpacking structures on the TCP connection.

## Warning

This is my first from scratch application in Swift and in SwiftUI and it shows.  I know this code is crufty and bad, even as an inexperienced Swift coder.  It was created as part of the KansasFest 2021 HackFest contest so I only had so much time for code cleanup.  I plan to improve the code and the UI in the future.

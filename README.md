#  ListenerApp

This is an iOS app that connects to an Apple IIgs over a network and streams text to it from voice dicatation.

It relies on the [Speech Framework](https://developer.apple.com/documentation/speech) built into recent versions of iOS.

This app uses [SwiftSocket v2.1.0](https://github.com/swiftsocket/SwiftSocket/tree/2.1.0) for opening the TCP connection to the Apple IIgs.
It also uses [BinUtils](https://github.com/nst/BinUtils) for packing/unpacking structures on the TCP connection.

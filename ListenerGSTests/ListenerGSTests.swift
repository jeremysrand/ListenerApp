//
//  ListenerGSTests.swift
//  ListenerGSTests
//
//  Created by Jeremy Rand on 2021-07-16.
//

import XCTest
@testable import ListenerGS

class ListenerGSTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func waitForConnection(connection: GSConnection) {
        for _ in (1...1000) {
            if (connection.state != .connecting) {
                return
            }
            usleep(10000)
        }
    }
    
    func testNoConnection() throws {
        let connection = GSConnection()
        connection.setMainQueueForTest()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        connection.connect(destination: "127.0.0.1")
        connection.waitForReadQueue()
        connection.waitForMain()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNotNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
    }
    
    func testNormalPath() throws {
        let connection = GSConnection()
        connection.setMainQueueForTest()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let server = GSServerMock()
        
        connection.connect(destination: "127.0.0.1")
        XCTAssertEqual(connection.state, .connecting)
        XCTAssert(server.accept())
        
        XCTAssert(server.hasClient())
        connection.waitForMain()
        waitForConnection(connection: connection)
        
        XCTAssertEqual(connection.state, .connected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let speechForwarder = SpeechForwarderMock()
        XCTAssert(!speechForwarder.isListening)
        
        connection.listen(speechForwarder: speechForwarder)
        XCTAssert(server.getListenState(isListening: true))
        connection.waitForMain()
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        connection.set(text: "Hello, world!")
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, world!")
        
        XCTAssertEqual(server.getText(), "Hello, world!")
        
        connection.set(text: "Rewrite everything...")
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Rewrite everything...")
        
        connection.set(text: "Hello, everyone!")
        connection.stopListening()
        
        XCTAssert(!speechForwarder.isListening)
        XCTAssertEqual(connection.state, .stoplistening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, everyone!")
        
        XCTAssert(server.sendMore())
        connection.waitForMain()
        connection.waitForWriteQueue()
        XCTAssertEqual(server.getText(), "\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}\u{7f}everyone!")
        
        connection.waitForMain()
        XCTAssert(server.getListenState(isListening: false))
        
        XCTAssertEqual(connection.state, .connected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, everyone!")
        
        server.disconnect()
        connection.waitForReadQueue()
        connection.waitForMain()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, everyone!")
    }
    
    func testDisconnectWhileListening() throws {
        let connection = GSConnection()
        connection.setMainQueueForTest()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let server = GSServerMock()
        
        connection.connect(destination: "127.0.0.1")
        XCTAssertEqual(connection.state, .connecting)
        XCTAssert(server.accept())
        
        XCTAssert(server.hasClient())
        connection.waitForMain()
        
        waitForConnection(connection: connection)
        XCTAssertEqual(connection.state, .connected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let speechForwarder = SpeechForwarderMock()
        XCTAssert(!speechForwarder.isListening)
        
        connection.listen(speechForwarder: speechForwarder)
        XCTAssert(server.getListenState(isListening: true))
        connection.waitForMain()
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        connection.set(text: "Hello, world!")
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, world!")
        
        XCTAssertEqual(server.getText(), "Hello, world!")
        
        connection.set(text: "Rewrite everything...")
        connection.disconnect()
        connection.waitForAllQueues()
        
        XCTAssert(!speechForwarder.isListening)
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Rewrite everything...")
        
        XCTAssert(server.getDisconnect())
    }
    
    func testBadSendMore() throws {
        let connection = GSConnection()
        connection.setMainQueueForTest()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let server = GSServerMock()
        
        connection.connect(destination: "127.0.0.1")
        XCTAssertEqual(connection.state, .connecting)
        XCTAssert(server.accept())
        
        XCTAssert(server.hasClient())
        connection.waitForMain()
        
        waitForConnection(connection: connection)
        XCTAssertEqual(connection.state, .connected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let speechForwarder = SpeechForwarderMock()
        XCTAssert(!speechForwarder.isListening)
        
        connection.listen(speechForwarder: speechForwarder)
        XCTAssert(server.getListenState(isListening: true))
        connection.waitForMain()
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        connection.set(text: "Hello, world!")
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, world!")
        
        XCTAssertEqual(server.getText(), "Hello, world!")
        
        connection.set(text: "Rewrite everything...")
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Rewrite everything...")
        
        connection.set(text: "Hello, everyone!")
        connection.stopListening()
        
        XCTAssert(!speechForwarder.isListening)
        XCTAssertEqual(connection.state, .stoplistening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, everyone!")
        
        XCTAssert(server.sendMoreBad())
        
        connection.waitForAllQueues()
        XCTAssert(server.getDisconnect())
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNotNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, everyone!")
    }
    
    func testServerDisconnect() throws {
        let connection = GSConnection()
        connection.setMainQueueForTest()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let server = GSServerMock()
        
        connection.connect(destination: "127.0.0.1")
        XCTAssertEqual(connection.state, .connecting)
        XCTAssert(server.accept())
        
        XCTAssert(server.hasClient())
        connection.waitForMain()
        
        waitForConnection(connection: connection)
        XCTAssertEqual(connection.state, .connected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        server.disconnect()
        connection.waitForReadQueue()
        connection.waitForMain()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
    }
    
    func testServerDisconnectionWhileListening() throws {
        let connection = GSConnection()
        connection.setMainQueueForTest()
        
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let server = GSServerMock()
        
        connection.connect(destination: "127.0.0.1")
        XCTAssertEqual(connection.state, .connecting)
        XCTAssert(server.accept())
        
        XCTAssert(server.hasClient())
        connection.waitForMain()
        
        waitForConnection(connection: connection)
        XCTAssertEqual(connection.state, .connected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        let speechForwarder = SpeechForwarderMock()
        XCTAssert(!speechForwarder.isListening)
        
        connection.listen(speechForwarder: speechForwarder)
        XCTAssert(server.getListenState(isListening: true))
        connection.waitForMain()
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "")
        
        connection.set(text: "Hello, world!")
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, world!")
        
        XCTAssertEqual(server.getText(), "Hello, world!")
        
        connection.set(text: "Rewrite everything...")
        
        XCTAssert(speechForwarder.isListening)
        XCTAssertEqual(connection.state, .listening)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Rewrite everything...")
        
        connection.set(text: "Hello, everyone!")
        server.disconnect()
        connection.waitForAllQueues()
        
        XCTAssert(!speechForwarder.isListening)
        XCTAssertEqual(connection.state, .disconnected)
        XCTAssertNil(connection.errorMessage)
        XCTAssertEqual(connection.textHeard, "Hello, everyone!")
    }
    
    func testDestructWhileConnected() throws {
        let server = GSServerMock()
        
        if (true) {
            let connection = GSConnection()
            connection.setMainQueueForTest()
            
            XCTAssertEqual(connection.state, .disconnected)
            XCTAssertNil(connection.errorMessage)
            XCTAssertEqual(connection.textHeard, "")
            
            connection.connect(destination: "127.0.0.1")
            XCTAssertEqual(connection.state, .connecting)
            XCTAssert(server.accept())
            
            XCTAssert(server.hasClient())
            connection.waitForMain()
            waitForConnection(connection: connection)
            
            XCTAssertEqual(connection.state, .connected)
            XCTAssertNil(connection.errorMessage)
            XCTAssertEqual(connection.textHeard, "")
        }
        
        XCTAssert(server.getDisconnect())
    }
    
    func testDestructWhileListening() throws {
        let server = GSServerMock()
        
        if (true) {
            let connection = GSConnection()
            connection.setMainQueueForTest()
            
            XCTAssertEqual(connection.state, .disconnected)
            XCTAssertNil(connection.errorMessage)
            XCTAssertEqual(connection.textHeard, "")
            
            connection.connect(destination: "127.0.0.1")
            XCTAssertEqual(connection.state, .connecting)
            XCTAssert(server.accept())
            
            XCTAssert(server.hasClient())
            connection.waitForMain()
            waitForConnection(connection: connection)
            
            XCTAssertEqual(connection.state, .connected)
            XCTAssertNil(connection.errorMessage)
            XCTAssertEqual(connection.textHeard, "")
            
            let speechForwarder = SpeechForwarderMock()
            XCTAssert(!speechForwarder.isListening)
            
            connection.listen(speechForwarder: speechForwarder)
            connection.waitForWriteQueue()
            connection.waitForMain()
            XCTAssert(server.getListenState(isListening: true))
            
            XCTAssert(speechForwarder.isListening)
            XCTAssertEqual(connection.state, .listening)
            XCTAssertNil(connection.errorMessage)
            XCTAssertEqual(connection.textHeard, "")
        }
        
        XCTAssert(server.getDisconnect())
    }

    /*
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    */

}

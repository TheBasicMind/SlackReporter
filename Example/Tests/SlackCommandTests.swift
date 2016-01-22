//
//  SlackCommandTests.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 17/01/2016.
//  Copyright © 2016 Paul Lancefield. All rights reserved.
//

import XCTest
@testable import SlackReporter

class SlackCommandTests: XCTestCase {

    override func setUp()
    {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBaseClassInitialisationSuccess()
    {
        var command: SlackCommand? = nil
        do {
            try command = SlackCommand(command: .Chat_postMessage, requiredArguments: (.Token, "AToken"), (.Channel, "#gen-feedback"), (.Text, "Some Text") )
        } catch {
            XCTFail("command must be instantiated")
        }
        XCTAssertNotNil(command, "")
    }
    
    
    func testBaseClassInitialisationSuccess_argumentOrderIrrelevant()
    {
        var command: SlackCommand? = nil
        do {
            try command = SlackCommand(command: .Chat_postMessage, requiredArguments: (.Channel, "#gen-feedback"), (.Token, "AToken"), (.Text, "Some Text") )
        } catch {
            XCTFail("command must be instantiated")
        }
        XCTAssertNotNil(command, "")
    }
    
    
    func testBaseClassInitialisationFailure_requiredArgumentMissing()
    {
        var command: SlackCommand? = nil
        do {
            try command = SlackCommand(command: .Chat_postMessage, requiredArguments: (.Token, "AToken"), (.Channel, "#gen-feedback") )
        } catch {
            // Early return equals success
            print(command)
            return
        }
         XCTFail("Command failure was not caught")
    }
    
    
    func testBaseClassInitialisationFailure_requiredArgMissingArgOrderIrrelevant()
    {
        var command: SlackCommand? = nil
        do {
            try command = SlackCommand(command: .Chat_postMessage, requiredArguments: (.Channel, "#gen-feedback"), (.Token, "AToken") )
        } catch {
            // Early return equals success
            print(command)
            return
        }
        XCTFail("Command failure was not caught")
    }
    
    
    func testSlackWebhook()
    {
        let command = SlackWebhook(webhookID: "AToken")
        
        var request: NSMutableURLRequest
        
        do {
            try request = command.URLRequest()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        XCTAssertEqual("https://hooks.slack.com/services/AToken", request.URL!.absoluteString)
    }
    
    
    func testSlackMessage()
    {
        /////////
        /////////
        ///
        /// Data
        
        let command = SlackPostMessage(channel: "AChannel", text: "Some Text")
        
        var request: NSMutableURLRequest
        
        ///////////
        ///////////
        ///
        /// Process
        
        do {
            try request = command.URLRequest()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        //////////
        //////////
        ///
        /// Result
        
        let data = request.HTTPBody
        
        guard data != nil else { XCTFail() ; return }
    
        let bodyText = NSString(data: data!, encoding: 4)
        
        XCTAssertTrue(bodyText!.hasPrefix("--Boundary"), "Body text in message command must start with HTML form markup")
        
        XCTAssertEqual("https://slack.com/api/chat.postMessage", request.URL!.absoluteString)
    }

    
    func testFormDataWithDictionary()
    {
        /////////
        /////////
        ///
        /// Data
        
        let commandType = CommandType.Chat_postMessage
        //let arg1 = (Arg.Token, "AToken" )
        //let arg2 = (Arg.Channel, "#gen-feedback")
        //let arg3 = (Arg.Text, "Some Text")
        
        ///////////
        ///////////
        ///
        /// Process
        
        var command: SlackCommand? = nil
        do {
            try command = SlackCommand(command: commandType, requiredArguments: (Arg.Token, "AToken" ), (Arg.Channel, "#gen-feedback"), (Arg.Text, "Some Text")  )
        } catch {
            XCTFail("command must be instantiated")
        }
        
        guard command != nil else { XCTAssertNotNil(command); return }
        
        do {
            try command!.setOptionalArguments( (.IconUrl, "IconURL"), (.AsUser, true)  )
        } catch {  XCTFail("command must allow optional arguments to be set") }
        
        
        var request: NSMutableURLRequest
        
        do {
            try request = command!.URLRequest()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        let data = request.HTTPBody
        
        guard data != nil else { XCTFail() ; return }
        
        let bodyText = NSString(data: data!, encoding: 4)
        
        // Check at least 1 required and 1 optional argument has been encoded
        XCTAssertTrue(bodyText!.containsString("Token"), "A required parameter has not been encoded")
        XCTAssertTrue(bodyText!.containsString("AToken"), "A required parameter has not been encoded")
        XCTAssertTrue(bodyText!.containsString("\"icon_url\""), "A required parameter has not been encoded")
        XCTAssertTrue(bodyText!.containsString("AToken"), "A required parameter has not been encoded")
        
        XCTAssertEqual("https://slack.com/api/chat.postMessage", request.URL!.absoluteString)
    }
    
    
    func testWebhookRequestURLSuccess()
    {
        var command: SlackCommand? = nil
        do {
            try command = SlackCommand(command: .Chat_postMessage, requiredArguments: (.Token, "AToken"), (.Channel, "#gen-feedback"), (.Text, "Some Text") )
        } catch {
            XCTFail("command must be instantiated")
        }
        
        guard command != nil else { XCTAssertNotNil(command); return }
        
        var request: NSMutableURLRequest
        
        do {
            try request = command!.URLRequest()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        XCTAssertEqual("https://slack.com/api/chat.postMessage", request.URL!.absoluteString)
    }
    
    
    func testRequestURLSuccess()
    {
        var command: SlackCommand? = nil
        do {
            try command = SlackCommand(command: .Chat_postMessage, requiredArguments: (.Token, "AToken"), (.Channel, "#gen-feedback"), (.Text, "Some Text") )
        } catch {
            XCTFail("command must be instantiated")
        }
        
        guard command != nil else { XCTAssertNotNil(command); return }
        
        var request: NSMutableURLRequest
        
        do {
            try request = command!.URLRequest()
        } catch {
            XCTFail("\(error)")
            return
        }
        
        XCTAssertEqual("https://slack.com/api/chat.postMessage", request.URL!.absoluteString)
    }
    
    
}

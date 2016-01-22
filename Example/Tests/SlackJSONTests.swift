//
//  SlackJSONTests.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 09/01/2016.
//  //  Copyright © 2016 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import XCTest
@testable import SlackReporter

class SlackJSONTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /**
     The attachments dictionary has a format fixed by the Slack API, so we
     therefore do a simple validation check the correct format is produced.
     */
    func test_attachmentsDictionaryGeneration() {
        /////////
        /////////
        ///
        /// Data
        
        // (identifier: String?, title: String?, result: String, rememberResult: Bool)
        let formData: [(identifier: String?, title: String?, result: String, rememberResult: Bool)] = [("An Identifier0", "A Title0", "Some form feedback from the user0", true),
               ("An Identifier1", "A Title1", "Some form feedback from the user1", true),
               ("An Identifier2", "A Title2", "Some form feedback from the user2", true)]
        
        let feedback = SRFeedback(pretext:"A slack form test", title: "Slack webhook message title", breadcrumb: "", formData: formData)
        
        ///////////
        ///////////
        ///
        /// Process

        let JSONAttachmentsDict = SlackFeedbackAttachment.slackAttachementContentDictWithFeedback(feedback, displayID: true, displayTitle: true)

        //////////
        //////////
        ///
        /// Result

        XCTAssertTrue(JSONAttachmentsDict["fields"]!.count == 3)
        XCTAssertTrue(NSJSONSerialization.isValidJSONObject(JSONAttachmentsDict))
    }
    
    
    func test_attachmentsDictionaryWithFeedbackGeneration() {
        /////////
        /////////
        ///
        /// Data
        
        // (identifier: String?, title: String?, result: String, rememberResult: Bool)
        let formData: [(identifier: String?, title: String?, result: String, rememberResult: Bool)] = [("An Identifier0", "A Title0", "Some form feedback from the user0", true),
            ("An Identifier1", "A Title1", "Some form feedback from the user1", true),
            ("An Identifier2", "A Title2", "Some form feedback from the user2", true)]
        
        let feedback = SRFeedback(pretext:"A slack form test", title: "Slack webhook message title", breadcrumb: "", formData: formData)
        
        ///////////
        ///////////
        ///
        /// Process
        
        let contentsDict = SlackFeedbackAttachment.slackAttachementContentDictWithFeedback(feedback, displayID: true, displayTitle: true)
        
        print(contentsDict)
        print((contentsDict["fields"] as! Array<NSObject>)[0])
        
        //////////
        //////////
        ///
        /// Result

        ///TODO: The following optionals should be safely unwrapped
        let feedbackValue = ( (contentsDict["fields"] as! [NSObject])[2] as! [NSObject : AnyObject])["value"] as! String

        XCTAssertTrue(contentsDict["fields"]?.count == 3)
        XCTAssertTrue(feedbackValue == "Some form feedback from the user2")
        XCTAssertTrue(NSJSONSerialization.isValidJSONObject(contentsDict))
    }
}

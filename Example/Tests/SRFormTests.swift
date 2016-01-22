//
//  SRFormTests.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 09/01/2016.
//  //  Copyright © 2016 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import XCTest
import Foundation
@testable import SlackReporter


class SRFormTests: XCTestCase
{
    
    override func setUp()
    {
        super.setUp()
    }
    
    override func tearDown()
    {
        super.tearDown()
    }
    
    class func elements()->[SRFormElement]
    {
        return [
            SRFormElement.init(identifier: "id", title: "title0", type: .Email,         feedbackValues: ["val1","val2","val3"], rememberResult: true),
            SRFormElement.init(identifier: "id", title: "title1", type: .Email,         feedbackValues: ["val1","val2","val3"], rememberResult: true),
            SRFormElement.init(identifier: "id", title: "title2", type: .Email,         feedbackValues: ["val1","val2","val3"], rememberResult: true)
        ]
    }
    
    
    class func section()->SRFormSection
    {
        return SRFormSection.init(title: "title", elements: elements(), footerText: "Footer text")
    }
    
    
    func test_init1()
    {
        let systemFeedback = SRSystemFeedback(withIdentifier: "id", title: "title", feedback: "Some feedback", feedbackLocation: .Top)
        XCTAssertTrue(systemFeedback.identifier == "id", "Identifier must not be nil")
    }
    
    
    func testFormElementInit()
    {
        let formElement = SRFormElement.init(identifier: "id", title: "title", type: .Email, feedbackValues: ["val1","val2","val3"], rememberResult: true)
        XCTAssertTrue(
            formElement.identifier == "id" &&
                formElement.title == "title" &&
                formElement.feedbackType == .Email &&
                formElement.feedbackValues.count == 3 &&
                formElement.rememberResult, "Identifier must not be nil")
    }
    
    
    func testFormSectionInit()
    {
        let formSection = SRFormTests.section()
        XCTAssertTrue(
            formSection.title == "title" &&
                formSection.elements.count == 3 &&
                formSection.footerText == "Footer text"
            , "Identifier must not be nil")
    }
    
    
    func testFormSectionSubscript()
    {
        let formSection = SRFormTests.section()
        XCTAssertTrue( formSection[1]!.title == "title1", "Identifier must not be nil")
    }

    func test_initialisationWithDefaultForm()
    {
        /////////
        /////////
        ///
        /// Data
        
        ///////////
        ///////////
        ///
        /// Process
        
        let form = SRForm.init(title: nil, sections: nil, systemFeedbackElements: nil)
        
        //////////
        //////////
        ///
        /// Result
        
        XCTAssertTrue(form.displayID)
        XCTAssertFalse(form.displayTitle)
        XCTAssertTrue(form.title == "General Feedback")
        XCTAssertTrue(form.sections.count == 3)
        XCTAssertTrue(form.token == "")
        XCTAssertTrue(form.systemFeedback.count == 1)
        XCTAssertTrue(form.systemFeedback[0].title == "Device type")
    }
    
    
    func test_initialisationWithDefaultFormArray()
    {
        /////////
        /////////
        ///
        /// Data
        
        ///////////
        ///////////
        ///
        /// Process
        
        let forms = SRForm.defaultForms()
        
        //////////
        //////////
        ///
        /// Result
        
        XCTAssertTrue(forms.count == 3)
        let form0 = forms[0]
        XCTAssertTrue(form0.displayID)
        XCTAssertFalse(form0.displayTitle)
        XCTAssertTrue(form0.title == "General Feedback")
        XCTAssertTrue(form0.sections.count == 3)
        XCTAssertTrue(form0.token == "")
        XCTAssertTrue(form0.systemFeedback.count == 1)
        XCTAssertTrue(form0.systemFeedback[0].title == "Device type")
        let form1 = forms[1]
        XCTAssertTrue(form1.displayID)
        XCTAssertFalse(form1.displayTitle)
        XCTAssertTrue(form1.title == "Improvement suggestion")
        XCTAssertTrue(form1.sections.count == 3)
        XCTAssertTrue(form1.token == "")
        XCTAssertTrue(form1.systemFeedback.count == 1)
        XCTAssertTrue(form1.systemFeedback[0].title == "Device type")
    }
}

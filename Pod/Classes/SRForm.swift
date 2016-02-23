//
//  SRForm.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 28/12/2015.
//  Copyright © 2015 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import Foundation
import UIKit

@objc protocol SRFeedbackReceptical
{
    var  feedback: String { set get }
    var  placeholderText: String? { set get }
    var  feedbackView: UIView? { get }
    func tapAnywhereAssignsFirstResponder()->Bool
}


@objc public enum SRFeedbackType: Int
{
    case SingleLineText
    case MultilineText
    case Email
    case ListSelection
    //case RatingSelection
    //case Image
}

@objc public enum SRSystemFeedbackLocation: Int
{
    case Top
    case Bottom
}


public class SRSystemFeedback: NSObject
{
    public var identifier: String = ""
    public var title: String = ""
    public var feedback: String = ""
    public var feedbackLocation: SRSystemFeedbackLocation = SRSystemFeedbackLocation.Top
    
    public init(withIdentifier identifier: String, title: String, feedback: String, feedbackLocation: SRSystemFeedbackLocation) {
        self.identifier = identifier
        self.title = title
        self.feedback = feedback
        self.feedbackLocation = feedbackLocation
    }
}


/**
 A Slack Reporter form element. An element is representative
 of e.g. each feedback entity, such as a singleLineText field
 or a MultiLineText field
 */
public class SRFormElement: NSObject, NSCoding
{
    public var identifier: String
    public var title: String
    public var feedbackType: SRFeedbackType
    public var feedbackValues: [String]
    public var rememberResult: Bool
    
    /**
     Returns a Slack Reporter form element definition object.
     - parameter identifier: The identifier for a form element. Cannot be nil. The
    identifier does not have to be unique, but may be used to disambiguate form elements with
    the same Title used accross multiple forms. The SRForm object has parameters which allow
    it to be determined if form identifiers or titles or both are displayed in the Slack
    feedback message.
     - parameter title: The title of the form element, displayed to the user.
     - parameter type: The type of the form element
     - parameter feedbackValues: An array of element values, must be of type NSString, may be nil.
     Element values are only utilised by TextEntry and ListSelection feedback types. For the
     text entry type only the first string in the array is used as placeholder text, for the
     ListSelection type the array is used to generate the list selector item list.
     - parameter description: An optional description that can be used to provide the user
     with more informaton about the kind of feedback sought.
     */
    public init(identifier:String, title:String, type:SRFeedbackType, feedbackValues:[String], rememberResult:Bool)
    {
        self.identifier         = identifier
        self.title              = title
        feedbackType            = type
        self.feedbackValues     = feedbackValues
        self.rememberResult     = rememberResult
    }
    
    
    public required convenience init?(coder aDecoder: NSCoder)
    {
        let identifier = aDecoder.decodeObjectForKey("identifier") as! String
        let title = aDecoder.decodeObjectForKey("title") as! String
        let feedbackType = SRFeedbackType(rawValue: aDecoder.decodeIntegerForKey("feedbackType") )!
        let feedbackValues:[String] = aDecoder.decodeObjectForKey("feedbackValues") as! [String]
        let rememberResult = aDecoder.decodeBoolForKey("rememberResult")
        
        self.init(                  identifier:     identifier,
                                    title:          title,
                                    type:           feedbackType,
                                    feedbackValues: feedbackValues,
                                    rememberResult: rememberResult)
    }
    
    
    public func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(identifier, forKey: "identifier")
        aCoder.encodeObject(title, forKey: "title")
        aCoder.encodeInteger(Int(feedbackType.rawValue), forKey: "feedbackType")
        aCoder.encodeObject(feedbackValues, forKey: "feedbackValues")
        aCoder.encodeBool(rememberResult, forKey: "rememberResult")
    }
    
    
    public override var description: String
        {
        get {
            return "SRFormElement title:\(identifier), title:\(title), feedbackType:\(feedbackType), feedbackValues:\(feedbackValues) rememberResult:\(rememberResult)"
        }
    }
}


/**
 A Slack Reporter form element. A section represents a group of table
 elements and can ensure title text is displayed above the group 
 holds the elements themselves and ensures footer text is displayed
 below the group.
 */
public class SRFormSection: NSObject, NSCoding
{
    public var title: String
    public var elements: [SRFormElement]
    public var footerText: String?
    
    public subscript(element: Int)->SRFormElement?
    {
        get {
            guard elements.indices.contains(element) else {
                return nil
            }
            return elements[element]
        }
    }
    
    /**
     Returns a Slack Reporter form section object.
     - parameter title: the title of the form element, displayed to the user. If the section has no title pass a zero length string.
     - parameter elements: an array of SRElements to be displayed within the section
     - parameter footerText: subscript text description displayed below the section. Typically used for providing directions qualifying what is expected of the user.
     */
    public init(title:String, elements:[SRFormElement], footerText:String?)
    {
        self.title              = title
        self.elements           = elements
        self.footerText         = footerText
        super.init()
    }
    
    
    public required convenience init?(coder aDecoder: NSCoder)
    {
        let title = aDecoder.decodeObjectForKey("title") as! String
        let someElements = aDecoder.decodeObjectForKey("elements") as! NSArray
        let myFooterText = aDecoder.decodeObjectForKey("footerText") as! String
        guard let swiftElements = someElements as? [SRFormElement] else {
            // downcastedSwiftArray contains only NSView objects
            return nil
        }
        
        self.init(  title: title, elements: swiftElements, footerText: myFooterText )
    }
    
    
    public func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(title, forKey: "title")
        aCoder.encodeObject(elements, forKey: "elements")
        aCoder.encodeObject(footerText, forKey: "footerText")
    }
    
    
    public override var description: String
        {
        get {
            return "SRFormElement title:\(title), elements:\(elements), footerText:\(footerText)"
        }
    }
}


/**
 A Slack Reporter form element. An element can represent a table group header
 */
public class SRForm: NSObject, NSCoding
{
    public var title: String
    public var channel: String = ""
    public var sections: [SRFormSection]
    /**
     Add system feedback elements to this array to insert feedback that will be reported
     to Slack but withoug being shown in the form. This can be used, for instance
     to supply information that doesn't require user input such as the device type.
     Indeed the default forms include the device type and software system.
     */
    public var systemFeedback: [SRSystemFeedback]
    public var token: String = ""
    
    /**
     If this is checked, the form ID of each element is shown in the report to slack. 
     If displayTitle is also checked, both will be shown.
    */
    public var displayID: Bool = true
    
    /**
     If this is checked, the form title of each element is shown in the report to slack
     if displayID is also checked, both will be shown
    */
    public var displayTitle: Bool = false
    
    /**
     A static function to get the default form with dynamic project name insertion
     */
    private class func defaultFormContent()->[SRFormSection]
    {
        let details             = NSLocalizedString("Your details", comment:"Label given to Your Details form element group")

        let name                = NSLocalizedString("Name", comment:"Label given to First Name field")
        let email               = NSLocalizedString("Email", comment:"Label given to Email field")
        
        let defaultSection1Elements = [
            SRFormElement(identifier: name, title: name, type: .SingleLineText, feedbackValues: [], rememberResult: true),
            SRFormElement(identifier: email, title: email, type: .Email, feedbackValues: [], rememberResult: true),
        ]
        
        let remember            = NSLocalizedString("You only need to provide these details once. We will remember them from now on.", comment:"Subsection comment given to your details form element group")

        let feedback            = NSLocalizedString("Feedback", comment:"ID given to Feedback field")

        let readinessTitle      = NSLocalizedString("Readiness", comment: "Title for readiness feedback form element")
        let readinessOption1    = NSLocalizedString("Ready for launch", comment: "readiness form feedback option 1")
        let readinessOption2    = NSLocalizedString("Still a Beta", comment: "readiness form feedback option 2")
        let readinessOption3    = NSLocalizedString("Not even a beta", comment: "readiness form feedback option 3")
        
        let defaultSection2Element = [
            SRFormElement( identifier:     readinessTitle,
                                title:          readinessTitle,
                                type:           .ListSelection,
                                feedbackValues: [readinessOption1,readinessOption2,readinessOption3],
                                rememberResult: false)]
        
        let defaultSection3Elements = [
            SRFormElement(identifier: feedback, title: "", type: .MultilineText, feedbackValues: [], rememberResult: false)]
        
        let appName: String = ", " + ((NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as? String) ?? "")
        
        let ourReadiness    = NSLocalizedString("Tell, as a prospective user, how ready you think the app is for launch", comment:"Subsection comment for Feedback form element group")
        let tellUs          = NSLocalizedString("Tell us what you think of this app\(appName)", comment:"Subsection comment for Feedback form element group")
        
        let ourSections:[SRFormSection] = [
            SRFormSection(title: details, elements: defaultSection1Elements, footerText: remember),
            SRFormSection(title: "", elements: defaultSection2Element, footerText: ourReadiness),
            SRFormSection(title: feedback, elements: defaultSection3Elements, footerText: tellUs)
        ]
        
        return ourSections
    }

    
    /**
     Improvement suggestion form sections
     */
    private static func defaultFeatureSuggestionSections()->[SRFormSection]
    {
        //////////////////////
        //////////////////////
        ////
        //// Section 1 Details
        
        let section1Header      = NSLocalizedString("Your Details", comment:"Label given to Your Details form element group")
        
        let name                = NSLocalizedString("Name", comment:"Label given to First Name field")
        let email               = NSLocalizedString("Email", comment:"Label given to Email field")
        
        let section1Elements = [
            SRFormElement(identifier: name, title: name, type: .SingleLineText, feedbackValues: [], rememberResult: true),
            SRFormElement(identifier: email, title: email, type: .Email, feedbackValues: [], rememberResult: true),
        ]
        
        let section1Footer      = NSLocalizedString("You only need to provide these details once. We will remember them from now on.", comment:"Form subsection comment")
        
        ///////////////////////////
        ///////////////////////////
        ////
        //// Section 2 Problem Type
        
        let section2Header      = NSLocalizedString("Feature suggestion", comment: "Form section header")
        let title               = NSLocalizedString("Title", comment: "User provided name for the feature suggestion")
        let problemType         = NSLocalizedString("Type", comment: "Feature suggestion type feedback element")
        let pt1                 = NSLocalizedString("Existing feature improvement", comment: "Form option")
        let pt2                 = NSLocalizedString("New feature suggestion", comment: "Form option")
        
        let section2Elements = [
            SRFormElement( identifier:     title,
                                title:          title,
                                type:           .SingleLineText,
                                feedbackValues: [],
                                rememberResult: false),
            SRFormElement( identifier:     problemType,
                                title:          problemType,
                                type:           .ListSelection,
                                feedbackValues: [pt1,pt2],
                                rememberResult: false),]
        
        //////////////////////////////////
        //////////////////////////////////
        ////
        //// Section 3 Description
        
        let section3Header          = NSLocalizedString("Description", comment:"Section header")
        
        let section3Elements = [
            SRFormElement(identifier: section3Header, title: "", type: .MultilineText, feedbackValues: [], rememberResult: false)
        ]
        
        let section3Footer          = NSLocalizedString("Please describe the improvement/suggestion.", comment:"Form section footer")
        
        let ourSections:[SRFormSection] = [
            SRFormSection(title: section1Header, elements: section1Elements, footerText: section1Footer),
            SRFormSection(title: section2Header, elements: section2Elements, footerText: nil),
            SRFormSection(title: section3Header, elements: section3Elements, footerText: section3Footer)
        ]
        
        return ourSections
    }
    
    /**
     Problem report form sections
     */
    private static func defaultProblemReportSections()->[SRFormSection]
    {
        //////////////////////
        //////////////////////
        ////
        //// Section 1 Details
        
        let section1Header      = NSLocalizedString("Your details", comment:"Label given to Your Details form element group")
        
        let name                = NSLocalizedString("Name", comment:"Label given to First Name field")
        let email               = NSLocalizedString("Email", comment:"Label given to Email field")
        
        let section1Elements = [
            SRFormElement(identifier: name, title: name, type: .SingleLineText, feedbackValues: [], rememberResult: true),
            SRFormElement(identifier: email, title: email, type: .Email, feedbackValues: [], rememberResult: true),
        ]
        
        let section1Footer      = NSLocalizedString("You only need to provide these details once. We will remember them from now on.", comment:"Form subsection comment")
        
        ///////////////////////////
        ///////////////////////////
        ////
        //// Section 2 Problem Type

        let section2Header      = NSLocalizedString("Problem Details", comment:"Form section title")

        let issueTitle          = NSLocalizedString("Problem Title", comment: "User provided name for the issue")

        let problemType         = NSLocalizedString("Type", comment: "Title Problem Report type feedback element")
        let pt1                 = NSLocalizedString("Bug", comment: "Form option")
        let pt2                 = NSLocalizedString("Text/Language", comment: "Form option")
        let pt3                 = NSLocalizedString("Usability Issue", comment: "Form option")
        let pt4                 = NSLocalizedString("Other", comment: "Form option")
        
        let reproducibility     = NSLocalizedString("Frequency", comment: "Title of Problem Report field asking for reproducibility information")
        let r1                  = NSLocalizedString("100% Reproducible", comment: "Form option")
        let r2                  = NSLocalizedString("Occurs often", comment: "Form option")
        let r3                  = NSLocalizedString("Occurs occassionaly", comment: "Form option")
        let r4                  = NSLocalizedString("Very rarely but more than once", comment: "Form option")
        let r5                  = NSLocalizedString("Only seen once", comment: "Form option")
        let r6                  = NSLocalizedString("Shucks, I haven't tried to reproduce it", comment: "Form option")
        
        let section2Elements = [
            SRFormElement( identifier: issueTitle,
                                title: issueTitle,
                                type: .SingleLineText,
                                feedbackValues: [],
                                rememberResult: false),
            SRFormElement( identifier:     problemType,
                                title:          problemType,
                                type:           .ListSelection,
                                feedbackValues: [pt1,pt2,pt3,pt4],
                                rememberResult: false),
            SRFormElement( identifier:     reproducibility,
                                title:          reproducibility,
                                type:           .ListSelection,
                                feedbackValues: [r1,r2,r3,r4,r5,r6],
                                rememberResult: false)
        ]
        
        let section2Footer      = NSLocalizedString("Let us know if you can reproduce the issue. Accurate use of this field helps us greatly", comment:"Subsection comment given to your details form element group")
        
        //////////////////////////////////
        //////////////////////////////////
        ////
        //// Section 3 Preconditions
        
        let section3Header          = NSLocalizedString("Preconditions", comment:"ID given to Feedback field")
        
        let section3Elements = [
            SRFormElement(identifier: section3Header, title: "", type: .MultilineText, feedbackValues: [], rememberResult: false)]
        
        let section3Footer          = NSLocalizedString("Please describe the steps you took leading up to the issue.", comment:"Form section footer")
        
        //////////////////////////////////
        //////////////////////////////////
        ////
        //// Section 4 Description
        
        let section4Header          = NSLocalizedString("Problem Description", comment:"Section header")
        
        let resultField             = NSLocalizedString("Result", comment:"Field title")
        let rf1                     = NSLocalizedString("Suboptimal Experience", comment: "Form option")
        let rf2                     = NSLocalizedString("Hang - No input possible", comment: "Form option")
        let rf3                     = NSLocalizedString("Hang - Slow/bad input possible", comment: "Form option")
        let rf4                     = NSLocalizedString("Crash to homescreen", comment: "Form option")
        let rf5                     = NSLocalizedString("Other", comment: "Form option")
        
        let descriptionField        = NSLocalizedString("Problem Description", comment:"Field title")
        
        let section4Elements = [
            SRFormElement(identifier: resultField, title: resultField, type: .ListSelection, feedbackValues: [rf1,rf2,rf3,rf4,rf5], rememberResult: false),
            SRFormElement(identifier: descriptionField, title: "", type: .MultilineText, feedbackValues: [], rememberResult: false)
        ]
        
        let section4Footer          = NSLocalizedString("Please describe the problem and the result.", comment:"Form section footer")
        
        let ourSections:[SRFormSection] = [
            SRFormSection(title: section1Header, elements: section1Elements, footerText: section1Footer),
            SRFormSection(title: section2Header, elements: section2Elements, footerText: section2Footer),
            SRFormSection(title: section3Header, elements: section3Elements, footerText: section3Footer),
            SRFormSection(title: section4Header, elements: section4Elements, footerText: section4Footer)
        ]
        
        return ourSections
    }
    
    private static func defaultSystemFeedbackElements()->[SRSystemFeedback]
    {
        return [SRSystemFeedback(withIdentifier: "Device type", title: "Device type", feedback: UIDevice.currentDevice().modelName, feedbackLocation: .Bottom)]
    }
    
    /**
     The designated intialiser returning a Slack Reporter form object.
     
     see Settings->iTunes & App Stores on the iphone
     for an example of the layout you can expect to see.
     
     Create your own custom form as follows:
     
     ```
     let elmnt1 = SRFormElement(title:          "Email",
     type:           .Email,
     feedbackValues: nil,
     rememberResult: true)
     let elmnt2 = SRFormElement(title:          "Feedback",
     type:           .MultilineText
     feedbackValues: nil
     rememberResult: false)
     
     let sctnA = SRFormSection(title:    "A Section Title",
     elements: [elmnt1, elmnt2],
     footer:   "Descriptive text in the section footer")
     
     let form = SRForm(title:"My SLForm", sections:[sctnA])
     ```
     - parameter title: the title of the form. May be nil 
     in which case a default title is given. If you want the title
     to be blank, pass in an empty string
     - parameter sections: an array of SRFormSection objects. May be
     nil, in which case a simple default feedback form will be generated.
     */

    subscript(section: Int)->SRFormSection?
    {
        get {
            guard sections.indices.contains(section) else {
                return nil
            }
            return sections[section]
        }
    }
    
    subscript(section: Int, item: Int)->SRFormElement?
    {
        get {
            guard sections.indices.contains(section) else {
                return nil
            }
            guard sections[section].elements.indices.contains(item) else {
                return nil
            }
            return sections[section].elements[item]
        }
    }
    
    /**
     The designated initialiser for a SlackReporter form.
    */
    public init(title:String?, sections:[SRFormSection]?, systemFeedbackElements:[SRSystemFeedback]?)
    {
        self.title              = title ?? NSLocalizedString("General Feedback", comment:"Title label given to form")
        self.sections           = sections ?? SRForm.defaultFormContent()
        self.systemFeedback     = systemFeedbackElements ?? SRForm.defaultSystemFeedbackElements()
        super.init()
    }
    
    
    public static func defaultForms()->[SRForm]
    {
        return [SRForm(title:nil, sections:nil, systemFeedbackElements: nil), SRForm.improvementReportForm(), SRForm.problemReportForm()]
    }
    
    
    public static func improvementReportForm()->SRForm
    {
        return SRForm(title:"Improvement suggestion", sections: defaultFeatureSuggestionSections(), systemFeedbackElements: nil )
    }
    
    
    public static func problemReportForm()->SRForm
    {
        return SRForm(title:"Report problem", sections: defaultProblemReportSections(), systemFeedbackElements: nil )
    }
    
    
    public required convenience init?(coder aDecoder: NSCoder)
    {
        let title = aDecoder.decodeObjectForKey("title") as! String
        let someSections = aDecoder.decodeObjectForKey("sections") as! NSArray
        guard let swiftSections = someSections as? [SRFormSection] else {
            // downcastedSwiftArray contains only NSView objects
            return nil
        }
        
        self.init(  title: title, sections: swiftSections, systemFeedbackElements: nil )
    }
    
    
    public func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(title, forKey: "title")
        aCoder.encodeObject(sections, forKey: "sections")
    }
    
    
    public override var description: String
    {
        get {
            return "SRForm title:\(title), sections:\(sections)"
        }
    }
}
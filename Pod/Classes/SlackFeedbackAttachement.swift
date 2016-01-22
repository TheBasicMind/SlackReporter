//
//  SlackJSON.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 04/01/2016.
//  Copyright © 2016 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import Foundation

struct SRFeedback {
    var pretext: String = ""
    var title: String = ""
    var breadcrumb: String? = nil ///TODO: Breadcrumb to display view controller hierarchy
    var formData: [(identifier: String?, title: String?, result: String, rememberResult: Bool)]
}

class SlackFeedbackAttachment
{
    /**
    Produces a JSON compatible rendition of form data submission meeting the Slack 
     API requirments.
     - parameter pretext: The introductory text displayed above a Slack Message 
     "attachment" (in Slack terminology, the attachment is a rich text object we 
     use to display our form data)
     - parameter title: The form title
     - parameter breadcrumb: Currently unused - will be used to provide a record of 
     the view controller heirarchy at the time Slack Reporter is invoked
     - parameter formData: An array of tupples describing the actual form data
     - returns: An attachements dictionary with terms compatible with a single 
     element in the Slack "attachments" array
     ```
     slackMessageDictionary[ "attachments" ] = ThisArray
    ```
     */
    static func slackAttachmentDict( feedback: SRFeedback, displayID: Bool, displayTitle: Bool )->[String:AnyObject]
    {
        let contentDict = slackAttachementContentDictWithFeedback(feedback, displayID: displayID, displayTitle: displayTitle)
        return contentDict
    }
    
    
    static func slackAttachementFallback( feedback: SRFeedback)->String
    {
        /// TODO: Produce Slack fallback description
        var fallbackString = "\(feedback.pretext) \n"
        for (identifier, title, result, _) in feedback.formData
        {
            fallbackString.appendContentsOf("\(title ?? identifier ?? "No ID"): \(result)\n")
        }
        return fallbackString
    }
    
    /**
     Takes a feedback object and uses it to produce an entry in the attachment array 
     of a slack message
     - parameter feedback: A form feedback object
     - parameter displayID: Whether to display the field ids for each element of 
     user feedback
     - parameter displayTitle: Whether to display the field title for each element 
     of user feedback
     - returns: A dictionary representing a single item for inclusion in the 
     attachments array which is the collection type value that needs to be assigned 
     to the "attachments" argument
     ```
     slackMessageDictionary[ "attachments" ] = [ ThisDictionary ]
     ```
     */
    static func slackAttachementContentDictWithFeedback( feedback: SRFeedback, displayID: Bool, displayTitle: Bool )->[String:AnyObject]
    {
        // For reference, Slack's own JSON example:
        //
        // "fallback": "New ticket from Andrea Lee - Ticket #1943: Can't rest my password - https://groove.hq/path/to/ticket/1943",
        // "pretext": "New ticket from Andrea Lee",
        // "title": "Ticket #1943: Can't reset my password",
        // "title_link": "https://groove.hq/path/to/ticket/1943",
        // "text": "Help! I tried to reset my password but nothing happened!",
        // "color": "#7CD197"
        
        var contentDict:[String:AnyObject]  = ["pretext": feedback.pretext]
        contentDict["pretext"]              = feedback.pretext
        var fields: [[String:String]]       = []
        for (identifier, title, result, _) in feedback.formData
        {
            let IDText = displayID ? identifier ?? "" : ""
            let titleText = displayTitle ? title ?? "" : ""
            let separator = displayID && displayTitle ? ": " : ""
            let dict = ["title": IDText + separator + titleText, "value": result]
            fields.append(dict)
        }
        contentDict["fields"]               = fields
        contentDict["fallback"]             = SlackFeedbackAttachment.slackAttachementFallback(feedback)
        return contentDict
    }
}

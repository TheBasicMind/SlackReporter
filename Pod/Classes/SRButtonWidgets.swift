//
//  SRButtonWidgets.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 26/12/2015.
//  Copyright © 2015 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//


import Foundation
import UIKit


protocol SRButtonWidgetProtocol
{
    var forms: [SRForm] {get set}
    var initialTitle: String {get set}
}

/**
 A Slack Reporter widget bar button item containing
 data defining the user feedback form to be displayed.
*/
public class SRBarButtonItem: UIBarButtonItem, SRButtonWidgetProtocol
{
    var forms:[SRForm] = SlackReporter.sharedInstance().defaultForms
    var initialTitle = NSLocalizedString("Feedback", comment: "Forms feedback title")
    /**
     Initialise a slack reporter bar button item widget with an associated
     Slack Reporter form. Clients of this framework should use the public
     initialiser.
     */
    init?(_ coder: NSCoder?, image: UIImage?, landscapeImagePhone: UIImage?, target: AnyObject, action: Selector, forms: [SRForm]? )
    {
        if let coder = coder {
            super.init(coder: coder)
        }
        else
        {
            super.init()
        }
        self.image = image
        self.landscapeImagePhone = landscapeImagePhone
        self.target = target
        self.action = action
    }
    
    
    /**
     Initialise a slack reporter bar button item widget with an associated
     Slack Reporter form. The buttons target and action will be configured
     such that the user pressing button will submit the form.
     */
    public convenience init?(image: UIImage?, landscapeImagePhone: UIImage?, form: [SRForm])
    {
        self.init(nil, image:image, landscapeImagePhone:landscapeImagePhone, target:SlackReporter.sharedInstance(), action:  "displaySlackReporter:", forms:form )
    }
    
    
    required public convenience init?(coder aDecoder: NSCoder)
    {
        //TODO: Implement support object encoding and decoding in Forms class
        //let someForms = aDecoder.decodeObjectForKey("form") as? [SRForm]
        //if someForms != nil { self.forms = someForms! } // otherwise we have the default forms
        self.init(aDecoder, image: nil, landscapeImagePhone: nil, target: SlackReporter.sharedInstance(), action: "displaySlackReporter:", forms: nil)
    }
    
    
    override public func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(forms, forKey: "form")
        aCoder.encodeObject(initialTitle, forKey:"initialTitle")
    }
}

/**
 A Slack Reporter widget button containing
 data defining the user feedback form to be 
 displayed.
 */
public class SRButton: UIButton, SRButtonWidgetProtocol
{
    var forms: [SRForm] = SlackReporter.sharedInstance().defaultForms
    var initialTitle = NSLocalizedString("Feedback", comment: "Forms feedback title")
    
    /**
     Initialise a slack reporter button widget with an associated
     Slack Reporter form. Clients of this framework should use
     the public convenience intialiser
     */
    private init (_ aDecoder: NSCoder?, forms someForms: [SRForm]?, target:AnyObject, action: Selector)
    {
        if aDecoder != nil {
            super.init(coder: aDecoder!)!
        }
        else
        {
            super.init(frame: CGRectZero)
        }
        if let someForms = someForms { forms = someForms } else { self.forms = SlackReporter.sharedInstance().defaultForms }
        self.addTarget(target, action: action, forControlEvents: .TouchUpInside)
        self.setImage(SlackReporterStyleKit.imageOfSlackReporterButtonIcon, forState: .Normal)
    }
    
    /**
     Initialise a slack reporter button widget with an associated
     Slack Reporter form. The button's target and action will be configured
     such that the user pressing button will submit the form.
     */
    public convenience init (forms: [SRForm]?)
    {
        self.init(nil, forms: forms, target:SlackReporter.sharedInstance(), action: "displaySlackReporterForm:")
    }
    
    
    required public convenience init?(coder aDecoder: NSCoder)
    {
        self.init(aDecoder, forms: SlackReporter.sharedInstance().defaultForms, target: SlackReporter.sharedInstance(), action: "displaySlackReporter:" )
        //TODO: Implement support object encoding and decoding in Forms class
        //let someForms = aDecoder.decodeObjectForKey("form") as? [SRForm]
        // self.forms = aDecoder.decodeObjectForKey("form") as! [SRForm]
    }

    
    override public func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(forms, forKey: "form")
    }
}

/*
/**
 A Slack Reporter widget button containing
 data defining the user feedback form to be
 displayed.
 */
public class SRPeekingButton: SRButton
{
    //// TODO: Peeking button
}
*/

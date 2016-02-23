//
//  SlackReporter.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 22/12/2015.
//  Copyright © 2015 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import Foundation
import UIKit


@objc public enum SlackConnectionMode: Int
{
    case Webhook
    case Authenticated
}


@objc public protocol SRDelegate
{
    /**
     Implement this method in your SRDelegate if you want to be able to do validation
     of data as the user enters it in a Slack Reporter form element. This method will
     only be called for .MultilineText and .SingleLineText Slack Reporter field types.
     */
    optional func mediator( formViewController: AnyObject,
                            formField: AnyObject,
                            formElement: SRFormElement,
                            shouldChangeTextInRange range: NSRange,
                            replacementText: String) -> Bool
    optional func mediatorFormViewControllerDidEndEditing(  formViewController: AnyObject,
                                                            formField: AnyObject,
                                                            formElement: SRFormElement)
}

/**
 The subtle reason for having an internal delegate as distinct from
 the external delegate is that the internal delegate implementation of 
 the calls is non optional. This is stylistically slightly better if in the
 future we implement multiple form types.
*/
protocol SRInternalDelegate : class
{
    /**
     Implement this method in your SRDelegate if you want to be able to do validation
     of data as the user enters it in a Slack Reporter form element. This method will
     only be called for .MultilineText and .SingleLineText Slack Reporter field types. FormField
     will either be of a UITextField or UITextView type
     */
    func mediator(      formViewController: AnyObject,
                        formField: AnyObject,
                        formElement: SRFormElement,
                        shouldChangeTextInRange range: NSRange,
                        replacementText: String) -> Bool
    func mediatorFormViewControllerDidEndEditing(   formViewController: AnyObject,
                                                    formField: AnyObject,
                                                    formElement: SRFormElement)
}

/**
Instantiate and access shared instance via 'sharedInstance' property, e.g.,
'SlackReporter.sharedInstance'. Use the mediator instance either to vend
 slack reporter UIButton widget instances or UIBarButtonItem widget instances
 and use these to allow the user to invoke a feedback form, or implement
 shake to feedback functionality. An example of how this can be done from
 any view controller is provided here:
 
 ```
override func canBecomeFirstResponder() -> Bool
{
    return true
}

override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
    print("Motion began!")
}

override func motionCancelled(motion: UIEventSubtype, withEvent event: UIEvent?) {
    print("Motion cancelled!")
}

override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?)
{
    if motion == .MotionShake {
        // Passing in nil
        SlackReporter.sharedInstance.displaySlackReporterWithTitle(nil)
    }
}
 ```
*/
public class SlackReporter: NSObject, SRInternalDelegate
{
    private static let _sharedInstance = SlackReporter()
    
    /// The upload queue form submissions are made to, that ensures
    /// uploads are always completed
    private let _uploadCoordinator = SRWebServiceClient()
    
    /**
     If connection mode is set to .Webhook, a default Webhook
     id (just the number ID, not the whole URL) can be 
     assigned here if the WebhookID is not going to be
     supplied with each form. If the connection mode is 
     .Authenticated, then an authenticated token must be
     assigned here.
    */
    public var defaultToken: String {
        set (newToken) {
            _uploadCoordinator.defaultToken = newToken
        }
        get {
            return _uploadCoordinator.defaultToken
        }
    }
    
    /**
     A default set of Slack Reporter forms. If no forms
     array is provided to the
     */
    public var defaultForms: [SRForm] = SRForm.defaultForms()
    
    /**
     If connection mode is set to .Authenticated then
     a userName that should be used for posting to
     Slack should be set here. For the webhook
     connection mode, this value is ignored.
     */
    public var userName: String {
        set (newName) {
            _uploadCoordinator.userName = newName
        }
        get {
            return _uploadCoordinator.userName
        }
    }
    
    /**
     If connection mode is set to .Authenticated if
     the post should be as a user, or as a bot can
     be set here. True to post as a user, false to
     post as a bot.
     */
    public var postAsUser: Bool {
        set (asUser) {
            _uploadCoordinator.postAsUser = asUser
        }
        get {
            return _uploadCoordinator.postAsUser
        }
    }
    
    /**
     If set to true, prevents Slack Reporter
     writing cahcing form submissions to disk.
     Mostly useful during debugging.
     */
    public var disableQueue: Bool {
        set (ifDisable) {
            _uploadCoordinator.disableQueue = ifDisable
        }
        get {
            return _uploadCoordinator.disableQueue
        }
    }
    
    /// If the connection mode is set to Webhook, then assign
    /// a default webhookID to the token property
    public var connectionMode: SlackConnectionMode = .Webhook
    
    public weak var delegate: SRDelegate? = nil
    
    /// If 'true' a screen capture is sent with each report.
    public var autoScreenCapture = false
    
    /// If 'true' the view controller heirarchy "path" is included with each report.
    public var autoReportControllerHierarchy = false
    
    /// If not nil the app version number will be reported with every report.
    public var versionNumber: String?

    /// The initial title to use for the modal form view
    /// when the first screen allows forms to be selected
    public var defaultInitialTitle: String = NSLocalizedString("Feedback", comment: "Initial form title")
    
    /// If a form has been presented, its view controller conforming to SRFormController
    /// is cached here
    private var presentedFormViewController: UITableViewController?
    
    private var automaticScreenCaptureOnInvoke: Bool = false
    
    private var capturedScreen: UIImage?
    
    private override init() { }
    
    /**
     Instance
     */
    public class func sharedInstance() ->SlackReporter {
        // function accessible via objective C and Swift ensures shared instance is accessible
        // via Objective-C and Swift
        do {
            try _sharedInstance._uploadCoordinator.enqueueFormForUpload(nil, channel: "", name: "" )
        } catch { }
        return _sharedInstance
    }
    
    /**
    Produce a new preconfigured slack reporter bar button item. Throws an error if accessed
     before the serviceHookID has been defined.
    */
    static public func reporterBarButtonItemWithForm(forms:[SRForm]?)->UIBarButtonItem
    {
        let barButton = SRBarButtonItem(   nil,
                                                image:                  SlackReporterStyleKit.imageOfSlackReporterBarButtonIcon(),
                                                landscapeImagePhone:    SlackReporterStyleKit.imageOfSlackReporterBarButtonIcon(),
                                                target:                 self,
                                                action:                 "displaySlackReporter:",
                                                forms:                  nil)
        // Only optional due to NSCoder, we can force unwrap here
        return barButton!
    }
    
    /**
    Produce a new preconfigured slack reporter bar button item with a feedback and 
    */
    static public func reporterButtonItem(forms:[SRForm]?)throws ->UIButton
    {
        //let button = SRButton(forms: forms, target: self, action:"displaySlackReporterForm:")
        let button = SRButton(forms: nil)
        button.setImage(SlackReporterStyleKit.imageOfSlackReporterBarButtonIcon(), forState: .Normal)
        return button
    }
    
    /**
     Call to directly display a form in a popover
     - parameter form An array of SRFormSection objects. May be nil, in which
     case a default feedback form is displayed. Each form section object contains
     an array of one or more SRFormElement objects.
     */
    public func displaySlackReporterWithForms(forms: [SRForm]?, initialTitle:String?)
    {
        // it appears the both the window property and return value are optional
        // so we need a double force unwrap
        guard let vc = UIApplication.sharedApplication().delegate?.window!!.rootViewController else
        {
            return
        }
        
        if automaticScreenCaptureOnInvoke {
            captureView(vc.view)
        }
        
        let myForms = forms ?? defaultForms
        let tableViewController: UITableViewController
        let cancelString                        = NSLocalizedString("Cancel", comment: "Cancel form bar button item label")
        let submitString                        = NSLocalizedString("Submit", comment: "Sumbmit form bar button item label")
        let cancelButton                        = UIBarButtonItem(title: cancelString,
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: "dispelFormsController:")
        let submitButton = UIBarButtonItem(title: submitString,
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: "submitForm:")
        
        switch myForms.count {
        case 1:
            // Presenting a single form
            tableViewController = SRTableViewController(style: .Grouped, form: myForms[0], reporterDelegate: self)
            break
        default:
            // Presenting a navigable set of forms
            tableViewController = SROptionTableViewController(style: .Grouped, forms: myForms, reporterDelegate: self)
            break
        }
        tableViewController.title               = initialTitle
        let navController                       = SRNavigationController(rootViewController: tableViewController, submitButton: submitButton)
        navController.modalPresentationStyle    = .FormSheet
        
        tableViewController.navigationItem.leftBarButtonItem = cancelButton
        vc.presentViewController(navController, animated: true, completion: nil)
        presentedFormViewController = tableViewController
    }

    /**
    Called by the button widget or shake whilst upside down action.
     - parameter form An array of SRFormSection objects. May be nil, in which
     case a default feedback form is displayed. Each form section object contains
     an array of one or more SRFormElement objects.
    */
    public func displaySlackReporter(sender: AnyObject )
    {
        guard (sender is SRButtonWidgetProtocol) else {
            return
        }
        let buttonWidget = sender as! SRButtonWidgetProtocol
        let forms = buttonWidget.forms
        displaySlackReporterWithForms(forms, initialTitle: buttonWidget.initialTitle )
    }
    
    /**
     dispels the feedback form without taking any action
     */
    public func dispelFormsController(sender: AnyObject)
    {
        guard let vc = UIApplication.sharedApplication().delegate?.window!!.rootViewController else {
            return
        }
        vc.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    public func submitForm(sender: AnyObject)
    {
        // Ensure the latest form data is grabbed
        // even if the user has not finished editing the
        // current cell.
        
        if presentedFormViewController?.navigationController?.topViewController is SRTableViewController {
            let slackTableViewForm = presentedFormViewController!.navigationController!.topViewController as! SRTableViewController
            do {
                try submitForm(slackTableViewForm.form, formData: slackTableViewForm.formData())
            }
            catch
            {
                print("Error = \(error)")
            }
        }
        
        if let presenting = presentedFormViewController?.presentingViewController
        {
            presenting.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
    func submitForm(form: SRForm, var formData: [(identifier: String?, title: String?, result: String, rememberResult: Bool)]) throws
    {
        if self.defaultToken.isEmpty && form.token.isEmpty  {
            throw SRError.TokenNotDefined
        }
        
        // Add any top oriented system feedback fields
        var topFeedback: [(identifier: String?, title: String?, result: String, rememberResult: Bool)] = []
        let topSysFeedback: [SRSystemFeedback] = form.systemFeedback.filter({ return $0.feedbackLocation == .Top })
        for sysFeedback in topSysFeedback {
            topFeedback += [ (Optional(sysFeedback.identifier), Optional(sysFeedback.title), sysFeedback.feedback, false) ]
        }
        topFeedback += formData
        
        // Add any bottom oriented system feedback fields
        var bottomFeedback: [(identifier: String?, title: String?, result: String, rememberResult: Bool)] = []
        let bottomSysFeedback: [SRSystemFeedback] = form.systemFeedback.filter({ return $0.feedbackLocation == .Bottom })
        for sysFeedback in bottomSysFeedback {
            bottomFeedback += [ (Optional(sysFeedback.identifier), Optional(sysFeedback.title), sysFeedback.feedback, false) ]
        }
        
        formData += bottomFeedback
        
        let feedback = SRFeedback(  pretext:    "",
                                    title:      form.title ?? "",
                                    breadcrumb: nil,
                                    formData:   formData)
        let attachment = SlackFeedbackAttachment.slackAttachmentDict(   feedback,
                                                                        displayID: form.displayID,
                                                                        displayTitle: form.displayTitle)
        do {
            switch connectionMode {
            case .Webhook:
                try _uploadCoordinator.enqueueFormForUpload(attachment, webhookID: form.token, name: feedback.title )
            case .Authenticated:
                try _uploadCoordinator.enqueueFormForUpload(attachment, channel: form.channel, name:  feedback.title )
            }
            
        }
        catch
        {
            // The philosophy is that the reporter gets in the way of the beta
            // experience as little as possible, even if that means there are edge
            // cases where, rarely, we migh lose the odd feedback form. Generally
            // there should only be an error here for some rare event like lack of
            // file space - in which case the user has a bigger problem than beta 
            // reporting.
        }
    }
    
    
    func mediator(  formViewController: AnyObject,
                    formField: AnyObject,
                    formElement: SRFormElement,
                    shouldChangeTextInRange range: NSRange,
                    replacementText: String)-> Bool
    {
        guard let delegate = delegate else {
            return true
        }
        
        if let mediator = delegate.mediator {
            return mediator(    formViewController,
                                formField: formField,
                                formElement: formElement,
                                shouldChangeTextInRange: range,
                                replacementText:  replacementText)
        } else {
            return true
        }
    }
    
    
    func mediatorFormViewControllerDidEndEditing(   formViewController: AnyObject,
                                                    formField: AnyObject,
                                                    formElement: SRFormElement)
    {
        guard let delegate = delegate else {
            return
        }
        
        if let mediator = delegate.mediatorFormViewControllerDidEndEditing {
            mediator(formViewController, formField: formField, formElement: formElement)
        }
    }
    
    
    func captureView(view: UIView) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0);
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }
}


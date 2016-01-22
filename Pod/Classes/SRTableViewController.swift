//
//  SRViewController.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 28/12/2015.
//  Copyright © 2015 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import Foundation
import UIKit

enum SRFormType {
    case SinglePage
    //case PagingView
}

/**
Any 
 */
protocol SRFormController
{
    var form: SRForm { get }
    var presentingViewController: UIViewController? { get }
    func formData()->[(identifier: String?, title: String?, result: String, rememberResult: Bool)]
}


class SRFormHelper {
    func formControllerWithType(type: SRFormType, form:SRForm, delegate:SRInternalDelegate) -> SRFormController {
        switch type {
        case .SinglePage:
            return SRTableViewController(style: .Grouped, form: form, reporterDelegate: delegate)
        }
    }
}


struct SRTableViewConstants {
    static let formCellIdentifier = "SRFormCellIdentifier"
    static let optionCellIdentifier = "SROptionCellIdentifier"
}


public class SRNavigationController: UINavigationController
{
    var formSubmitButton: UIBarButtonItem?
    
    override private init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    override private init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    
    init(rootViewController: UIViewController, submitButton: UIBarButtonItem) {
        super.init(rootViewController: rootViewController)
        self.formSubmitButton = submitButton
    }

    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override public func viewDidLoad() {
        super.viewDidLoad()
        if topViewController is SRTableViewController {
            topViewController?.navigationItem.rightBarButtonItem = formSubmitButton
        }
    }
    
    
    override public func pushViewController(viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        if viewController is SRTableViewController {
            viewController.navigationItem.setRightBarButtonItem(formSubmitButton, animated: animated)
        }
    }
    

    override public func popViewControllerAnimated(animated: Bool) -> UIViewController? {
        let aViewController = super.popViewControllerAnimated(animated)
        if topViewController is SRTableViewController {
            topViewController?.navigationItem.setRightBarButtonItem(formSubmitButton, animated: animated)
        } else {
            topViewController?.navigationItem.setRightBarButtonItem(nil, animated: animated)
        }
        
        return aViewController
    }
    
    
    override public func popToRootViewControllerAnimated(animated: Bool) -> [UIViewController]? {
        let viewControllerArray = super.popToRootViewControllerAnimated(animated)
        if (topViewController is SRTableViewController) == false {
            topViewController?.navigationItem .setRightBarButtonItem(nil, animated: animated)
        }
        return viewControllerArray
    }
    
    
    override public func setViewControllers(viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        if topViewController is SRTableViewController || viewControllers.count == 0 {
            topViewController?.navigationItem.setRightBarButtonItem(formSubmitButton, animated: animated)
        } else {
            topViewController?.navigationItem.setRightBarButtonItem(nil, animated: animated)
        }
    }
}


public class SRTableViewCell: UITableViewCell, SRFeedbackReceptical
{
    var feedbackView: UIView? {
        get {
            var myView: UIView? = nil
            for view in self.contentView.subviews {
                if view.tag == 5 {
                    myView = view
                }
            }
            return myView
        }
    }
    
    
    var feedback: String {
        set {
            let feedbackView                = contentView.viewWithTag(5)
            if let feedbackView             = feedbackView as? UITextField {
                feedbackView.text           = newValue
            }
            else if let feedbackView        = feedbackView as? UITextView {
                feedbackView.text           = newValue
            }
        }
        get {
            let feedbackView                = contentView.viewWithTag(5)
            if let feedbackView             = feedbackView as? UITextField {
                return feedbackView.text ?? ""
            }
            else if let feedbackView        = feedbackView as? UITextView {
                return feedbackView.text ?? ""
            }
            return ""
        }
    }
    
    
    var placeholderText: String? {
        set {
            let feedbackView                = contentView.viewWithTag(5)
            if let feedbackView             = feedbackView as? UITextField {
                feedbackView.placeholder    = newValue
            }
        }
        get {
            let feedbackView                = contentView.viewWithTag(5)
            if let feedbackView             = feedbackView as? UITextField {
                return feedbackView.placeholder
            }
            else { return nil }
        }
    }
    
    
    func tapAnywhereAssignsFirstResponder()->Bool
    {
        let feedbackView = contentView.viewWithTag(5)
        if let feedbackView = feedbackView as? UITextField {
            return feedbackView.becomeFirstResponder()
        }
        else if let feedbackView = feedbackView as? UITextView {
            return feedbackView.becomeFirstResponder()
        }
        return false
    }
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    
    public required init?(coder aDecoder: NSCoder)
    {
        /// TODO: Decoding yet to be fully implemented
        super.init(coder: aDecoder)
    }
    
    
    /**
     Setup and add subviews and apply constraints according to
     the provided form element data
     - parameter formElement: The form element data
     */
    func configureLayoutForElement<T where T: UITextFieldDelegate, T: UITextViewDelegate >(formElement: SRFormElement, elementDelegate: T)
    {
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        
        ////////////////
        ////////////////
        ////
        //// Title label
        
        if formElement.title != "" {
            let aTitleLabel                 = UILabel.init(frame: CGRectZero)
            aTitleLabel.text                = formElement.title
            aTitleLabel.font                = font
            aTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(aTitleLabel)
        }
        
        ///////////////////////////////
        ///////////////////////////////
        ////
        //// Optionally a feedback view
        
        var aFeedbackView: UIView
        switch formElement.feedbackType {
        case .Email:
            aFeedbackView                           = UITextField.init(frame: CGRectZero)
            let aTextField = aFeedbackView as! UITextField
            aFeedbackView.translatesAutoresizingMaskIntoConstraints = false
            aTextField.delegate = elementDelegate
            aTextField.autocapitalizationType       = .None
            aTextField.autocorrectionType           = .No
            aTextField.spellCheckingType            = .No
            aTextField.font                         = font
            aTextField.textColor                    = UIColor.grayColor()
            contentView.addSubview(aFeedbackView)
        case .MultilineText:
            aFeedbackView                           = UITextView.init(frame: CGRectZero)
            let aTextView = aFeedbackView as! UITextView
            aTextView.translatesAutoresizingMaskIntoConstraints = false
            aTextView.delegate                      = elementDelegate
            aTextView.font                          = font
            aTextView.textColor                     = UIColor.grayColor()
            contentView.addSubview(aFeedbackView)
            let genConstraints                      = NSLayoutConstraint.constraintsWithVisualFormat("V:[feedback(120)]", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["feedback" : aFeedbackView])
            let aConstraint                         = genConstraints[0]
            aConstraint.priority                    = 900
            contentView.addConstraints([aConstraint])
            accessoryType                           = .None
        case .ListSelection:
            aFeedbackView                           = UITextField.init(frame: CGRectZero)
            let aTextField                          = aFeedbackView as! UITextField
            aTextField.translatesAutoresizingMaskIntoConstraints = false
            aTextField.delegate                     = elementDelegate
            aTextField.font                         = font
            aTextField.userInteractionEnabled       = false
            aTextField.textColor                    = UIColor.grayColor()
            accessoryType                           = .DisclosureIndicator
            contentView.addSubview(aFeedbackView)
        case .SingleLineText:
            fallthrough
        default:
            aFeedbackView                           = UITextField.init(frame: CGRectZero)
            aFeedbackView.translatesAutoresizingMaskIntoConstraints = false
            (aFeedbackView as! UITextField).delegate = elementDelegate
            (aFeedbackView as! UITextField).textColor = UIColor.grayColor()
            contentView.addSubview(aFeedbackView)
            break
        }
        aFeedbackView.tag = 5
    }
    
    
    private func configureConstraintsForViews(formElement: SRFormElement)
    {
        var views = [String: UIView]()
        var string: String
        var constraints: [NSLayoutConstraint]
        
        if formElement.title != "" {
            views           = ["title": self.contentView.subviews[0], "feedback": self.contentView.subviews[1]]
            string          = "H:|-[title(120)]-[feedback]-|"
            constraints     = NSLayoutConstraint.constraintsWithVisualFormat(string, options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views )
            contentView.addConstraints(constraints)
            string          = "V:|-[title]-|"
            constraints     = NSLayoutConstraint.constraintsWithVisualFormat(string, options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views )
            contentView.addConstraints(constraints)
        } else {
            views           = ["feedback": self.contentView.subviews[0]]
            string          = "H:|-[feedback]-|"
            constraints     = NSLayoutConstraint.constraintsWithVisualFormat(string, options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views )
            contentView.addConstraints(constraints)
        }
        
        string = "V:|-[feedback]-|"
        constraints = NSLayoutConstraint.constraintsWithVisualFormat(string, options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views )
        contentView.addConstraints(constraints)
    }
    
    
    override public func prepareForReuse() {
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }
    }
}


/**
 SlackReporter table view controller is presented by a SRButton or SRBarButtonItem
 widget and displayes the form elements defined in the button item's formElements
 array.
 */
public class SRTableViewController: UITableViewController, SRFormController, UITextViewDelegate, UITextFieldDelegate
{
    let form: SRForm
    weak var reporterDelegate: SRInternalDelegate? 
    
    // Form data stored by section and item so references
    // corresond with table sections and items so accessing and
    // modifying the data is a little easier
    private(set) var _formData: [ [(identifier: String?, title: String?, result: String, rememberResult: Bool)] ]
    private var editingCellIndexPath: NSIndexPath?
    
    /**
     Accepts an array where each object is of type
     SRFormElement
     */
    init(style: UITableViewStyle, form: SRForm, reporterDelegate: SRInternalDelegate?)
    {
        self.form = form
        self._formData = []
        self.reporterDelegate = reporterDelegate
        for section in form.sections {
            var elements: [(identifier: String?, title: String?, result: String, rememberResult: Bool)] = []
            for element in section.elements {
                elements.append( (identifier: element.identifier, title: element.title, result: "", rememberResult: element.rememberResult) )
            }
            _formData.append(elements)
        }
        super.init(style: style)
    }
    
    
    public required init?(coder aDecoder: NSCoder)
    {
        /// TODO: Decoding yet to be fully implemented
        self.form = aDecoder.decodeObjectForKey("form") as! SRForm
        self._formData = []
        for section in form.sections {
            var elements: [(identifier: String?, title: String?, result: String, rememberResult: Bool)] = []
            for element in section.elements {
                elements.append( (identifier: element.identifier, title: element.title, result: "", rememberResult: element.rememberResult) )
            }
            _formData.append(elements)
        }
        super.init(coder: aDecoder)
    }
    
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.registerClass(SRTableViewCell.self , forCellReuseIdentifier: SRTableViewConstants.formCellIdentifier)
        tableView.rowHeight                 = UITableViewAutomaticDimension
        tableView.estimatedRowHeight        = 120
        let userDefaults                    = NSUserDefaults.standardUserDefaults()
        navigationItem.hidesBackButton      = true
        let backButtonText                  = NSLocalizedString("Cancel", comment: "Cancel back button")
        navigationItem.leftBarButtonItem    = UIBarButtonItem.init(title: backButtonText, style: .Plain, target: self, action: "cancelViewController:")
        
        for (s, section) in form.sections.enumerate() {
            for i in section.elements.indices {
                let formElement = form[s]![i]!
                if formElement.rememberResult {
                    let value = userDefaults.valueForKey("com.SlackReporter.formElement.\(formElement.identifier)") as! String?
                    _formData[s][i].result = value ?? ""
                }
            }
        }
    }
    
    
    public func cancelViewController(sender: AnyObject)
    {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    public override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        // This will already have been done
        // when the form was submitted, but for
        // safety, in case during integration the
        // host apps are checking if the form 
        // that should be rememebered has has
        // been persisted we do it again here.
        grabFormData()
    }
    
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return form.sections.count
    }
    
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return form.sections[section].elements.count
    }
    
    
    public override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return form[section]!.title
    }
    
    
    public override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String?
    {
        return form[section]!.footerText
    }
    
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        // Configure the view layout and constraints
        let cell = tableView.dequeueReusableCellWithIdentifier(SRTableViewConstants.formCellIdentifier, forIndexPath: indexPath) as! SRTableViewCell
        let formElement = (form[indexPath.section]!.elements as [SRFormElement])[indexPath.item]
        cell.configureLayoutForElement(formElement, elementDelegate:self)
        cell.configureConstraintsForViews(formElement)
        
        // Now initialise any initial data the cell needs to display
        
        //let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = _formData[indexPath.section][indexPath.item]
        cell.feedback = data.result ?? ""
        
        if formElement.feedbackType == .ListSelection  {
            cell.placeholderText = NSLocalizedString("Select an Option", comment: "Select Option placeholder text for selection list control")
        }
        
        // Only selection lists allow
        cell.selectionStyle = .None
        
        return cell
    }
    
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        editingCellIndexPath = indexPath
        let formElement = (form[indexPath.section]!.elements as [SRFormElement])[indexPath.item]
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SRTableViewCell
        cell.tapAnywhereAssignsFirstResponder()
        if formElement.feedbackType == .ListSelection {
            let currentSelection = cell.feedback
            let optionsTableViewController = SROptionTableViewController(   style:              .Grouped,
                                                                            options:            formElement.feedbackValues,
                                                                            valueField:         cell.feedbackView! as! UITextField,
                                                                            currentSelection:   currentSelection,
                                                                            reporterDelegate:   self.reporterDelegate)
            navigationController?.pushViewController(optionsTableViewController, animated: true)
        }
    }
    
    
    /// We need to be able to take input from this form
    override public func canBecomeFirstResponder() -> Bool
    {
        return true
    }
    
    /// We pass on the text view data entry parsing to our own delegate, which is more generalised
    /// and may do all the validation, or may, for .MultilineText and .SingleLineText values, pass validation
    /// on to the user of the framework.
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        guard let reporterDelegate = reporterDelegate else {
            return true
        }
        
        guard let tableViewCell = textView.superview?.superview as? UITableViewCell else {
            return true
        }
        
        let indexPath       = tableView.indexPathForCell(tableViewCell)!
        let elementData     = form[indexPath.section]!.elements[indexPath.item]

        return reporterDelegate.mediator( self, formField: textView, formElement: elementData, shouldChangeTextInRange: range, replacementText: text)
    }
    
    
    func isValidEmail(testStr:String) -> Bool
    {
        let emailRegEx =  "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluateWithObject(testStr)
        return result
    }
    
    
    public func textFieldDidBeginEditing(textField: UITextField)
    {
        guard let tableViewCell = textField.superview?.superview as? UITableViewCell else {
            return
        }
        
        editingCellIndexPath       = tableView.indexPathForCell(tableViewCell)!
    }

    
    public func textViewDidBeginEditing(textView: UITextView)
    {
        guard let tableViewCell = textView.superview?.superview as? UITableViewCell else {
            return
        }
        
        editingCellIndexPath       = tableView.indexPathForCell(tableViewCell)!
    }
    
    
    /// We pass on the text view data entry parsing to our own delegate, which is more generalised
    /// and may do all the validation, or may, for .MultilineText and .SingleLineText values, pass validation
    /// on to the user of the framework.
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString repString: String) -> Bool
    {
        let elementData     = form.sections[editingCellIndexPath!.section].elements[editingCellIndexPath!.item]
        switch elementData.feedbackType {
        case .Email:
            let afterChange = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: repString)
            textField.textColor = isValidEmail(afterChange) ? UIColor.blackColor(): UIColor.redColor()
        default:
            break
        }
        guard let reporterDelegate = reporterDelegate else {
            return true
        }
        return reporterDelegate.mediator( self, formField: textField, formElement: elementData, shouldChangeTextInRange: range, replacementText: repString)
    }
    
    
    /// If a text view ends editing we process the form data and pass
    /// the call on to our delegate's protocol's version of the call.
    public func textViewDidEndEditing(textView: UITextView)
    {
        guard let reporterDelegate = reporterDelegate else {
            return
        }
        
        let elementData             = form.sections[editingCellIndexPath!.section].elements[editingCellIndexPath!.item]
        var formElementData         = _formData[editingCellIndexPath!.section][editingCellIndexPath!.item]
        formElementData.result      = textView.text
        _formData[editingCellIndexPath!.section][editingCellIndexPath!.item] = formElementData
        
        return reporterDelegate.mediatorFormViewControllerDidEndEditing( self, formField: textView, formElement: elementData)
    }
    
    
    /// If a text field ends editing we process the form data and pass
    /// the call on to our delegate's protocol's version of the call.
    public func textFieldDidEndEditing(textField: UITextField)
    {
        guard let reporterDelegate = reporterDelegate else {
            return
        }
        
        let elementData             = form.sections[editingCellIndexPath!.section].elements[editingCellIndexPath!.item]
        var formElementData         = _formData[editingCellIndexPath!.section][editingCellIndexPath!.item]
        formElementData.result      = textField.text ?? ""
        _formData[editingCellIndexPath!.section][editingCellIndexPath!.item] = formElementData
        
        return reporterDelegate.mediatorFormViewControllerDidEndEditing( self, formField: textField, formElement: elementData)
    }
    
    
    /// Ensure the feedback data is updated if the cell is about to disappear
    public override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        guard let cell = cell as? SRTableViewCell else {
            return
        }
        
        // Nothing to do if there is no cell being edited
        guard editingCellIndexPath != nil else {
            return
        }
        
        var formElementData             = _formData[editingCellIndexPath!.section][editingCellIndexPath!.item]
        if let textField = cell.feedbackView as? UITextField {
            formElementData.result      = textField.text ?? ""
            _formData[editingCellIndexPath!.section][editingCellIndexPath!.item] = formElementData
        }
        if let textView = cell.feedbackView as? UITextView {
            formElementData.result      = textView.text ?? ""
            _formData[editingCellIndexPath!.section][editingCellIndexPath!.item] = formElementData
        }
    }
    
    
    /// Update current editing cell with feedback
    func updateFeedbackForEditingCell(feedback:String)
    {
        var formElementData             = _formData[editingCellIndexPath!.section][editingCellIndexPath!.item]
        formElementData.result          = feedback
        _formData[editingCellIndexPath!.section][editingCellIndexPath!.item] = formElementData
    }
    
    
    public func grabFormData()
    {
        var syncRequired = false
        
        for indexPath in tableView.indexPathsForVisibleRows! {
            if let formObj = tableView.cellForRowAtIndexPath(indexPath) {
                var formElementData             = _formData[indexPath.section][indexPath.item]
                let formCell                    = formObj as! SRTableViewCell
                if let textField = formCell.feedbackView as? UITextField {
                    formElementData.result      = textField.text ?? ""
                    _formData[indexPath.section][indexPath.item] = formElementData
                }
                if let textView = formCell.feedbackView as? UITextView {
                    formElementData.result      = textView.text ?? ""
                    _formData[indexPath.section][indexPath.item] = formElementData
                }
                formCell.feedbackView?.resignFirstResponder()
                let formElement                 = form[indexPath.section]![indexPath.row]!
                if formElement.rememberResult {
                    NSUserDefaults.standardUserDefaults().setValuesForKeysWithDictionary(["com.SlackReporter.formElement.\(formElement.identifier)" : formCell.feedback])
                    syncRequired                = true
                }
            }
        }
        
        if syncRequired { NSUserDefaults.standardUserDefaults().synchronize() }
    }
    
    // Flattened form data so slightly easier to deal with
    // by our delegate object where really there is not much
    // need for knowing about table sections. We could have 
    // defined this as a property, but there is a side effect
    // of processing the form data - so better as a function.
    public func formData()->[(identifier: String?, title: String?, result: String, rememberResult: Bool)]
    {
        grabFormData()
        return _formData.flatMap( { $0} )
    }
}


/**
 SlackReporter table view controller for displaying both initial form
 selections and field options
 */
public class SROptionTableViewController: UITableViewController
{
    let options: [AnyObject]
    let valueField: UITextField?
    let currentSelection: String?
    weak var reporterDelegate: SRInternalDelegate?
    let indexPath: NSIndexPath?         = nil
    
    
    /**
    Private common
    */
    private init(style: UITableViewStyle, baseOptions: [AnyObject], valueField: UITextField?, currentSelection: String?, reporterDelegate: SRInternalDelegate?)
    {
        self.options                    = baseOptions
        self.valueField                 = valueField
        self.currentSelection           = currentSelection
        self.reporterDelegate           = reporterDelegate
        super.init(style: style)
    }

    /**
     Accepts an array where each object is of type
     SRFormElement
     */
    convenience init(style: UITableViewStyle, options: [String], valueField: UITextField, currentSelection: String?, reporterDelegate: SRInternalDelegate?)
    {
        self.init(style: style, baseOptions: options, valueField: valueField, currentSelection: currentSelection, reporterDelegate: reporterDelegate)
    }
    
    /**
     Accepts an array where each object is of type
     SRFormElement
     */
    convenience init(style: UITableViewStyle, forms: [SRForm], reporterDelegate: SRInternalDelegate?)
    {
        self.init(style: style, baseOptions: forms, valueField: nil, currentSelection: nil, reporterDelegate: reporterDelegate)
    }
    
    
    public convenience required init?(coder aDecoder: NSCoder)
    {
        /// TODO: Decoding yet to be fully implemented
        let opts = aDecoder.decodeObjectForKey("options") as! [String]
        let valField = UITextField(frame: CGRectZero)
        let currSelection               = ""
        self.init(style: .Grouped, baseOptions: opts, valueField: valField, currentSelection: currSelection,reporterDelegate: nil)
    }
    
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self , forCellReuseIdentifier: SRTableViewConstants.optionCellIdentifier)
        tableView.rowHeight             = UITableViewAutomaticDimension
        tableView.estimatedRowHeight    = 44
        tableView.delegate              = self
        tableView.dataSource            = self
        if isFormSelector() {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelViewController:")
        }
    }
    
    
    func isFormSelector()->Bool
    {
        return self.navigationController?.viewControllers.count == 1
    }
    
    
    public func cancelViewController(sender: AnyObject)
    {
        if self.navigationController == nil || self.navigationController?.viewControllers.count == 1 {
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
        else
        {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return options.count
    }
    
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(SRTableViewConstants.optionCellIdentifier, forIndexPath: indexPath)
        let option = self.options[indexPath.item]
        var cellLabelString: String

        if option is String {
            cellLabelString             = option as! String
        } else {
            cellLabelString             = (option as! SRForm).title
        }
        
        if cellLabelString == currentSelection && options is [String] {
            cell.accessoryType          = .Checkmark
        }
        
        cell.textLabel?.text            = cellLabelString
        cell.selectionStyle             = .None
        return cell
    }
    
    
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let option = self.options[indexPath.item]
        var cellLabelString: String
        
        if option is String {
            cellLabelString             = option as! String
            for cell in tableView.visibleCells {
                cell.accessoryType      = .None
            }
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            if cellLabelString == currentSelection && options is [String] {
                cell?.accessoryType     = .Checkmark
            }
            valueField?.text = cellLabelString
            let aViewController = navigationController?.viewControllers[1] as! UITableViewController
            if let formController       = aViewController as? SRTableViewController {
                formController.updateFeedbackForEditingCell(cellLabelString)
            }
            navigationController?.viewControllers[0]
            
            navigationController?.popViewControllerAnimated(true)
        } else {
            cellLabelString             = (option as! SRForm).title
            let form                    = option as! SRForm
            let tableViewController     = SRTableViewController.init(style: .Grouped, form: form, reporterDelegate: self.reporterDelegate)
            tableViewController.title   = form.title
            self.navigationController?.pushViewController(tableViewController, animated: true)
        }
    }

    
    /// We need to be able to take input from this form
    override public func canBecomeFirstResponder() -> Bool
    {
        return true
    }
}



# SlackReporter
A simple iOS framework allowing beta-test users to provide feedback using Slack. Super easy to integrate. Super easy to use.

[![Version](https://img.shields.io/cocoapods/v/SlackReporter.svg?style=flat)](http://cocoapods.org/pods/SlackReporter)
[![License](https://img.shields.io/cocoapods/l/SlackReporter.svg?style=flat)](http://cocoapods.org/pods/SlackReporter)
[![Platform](https://img.shields.io/cocoapods/p/SlackReporter.svg?style=flat)](http://cocoapods.org/pods/SlackReporter)

## Installation
To run the example project, clone the repo, navigate to the Example directory at the command line and run `pod install`

If you prefer to simply copy the source code to your app, use the Finder to grab the files in the subdirectory Pod/Classes and drop all of them in your XCode project. 

SlackReporter is available through [CocoaPods](http://cocoapods.org). To install
it via CocoaPods, add the following line to your Podfile:

```ruby
pod "SlackReporter"
```

## Integration
Integrating Slack Reporter into your own project couldn’t be easier (SlackReporter is written using Swift, but our integration testing utilises Objective C to enforce the discipline of ensuring the interface works well for Objective-C clients).

Add the following import statement to any view controller source files where you would like your beta test users to be able to invoke the forms (your root view controller is a good place)

```Objective-C
@import SlackReporter
```

Implement a mechanism to allow your users to invoke the feedback forms. My favourite is to display the forms if the user turns the device upside down and shakes. The following code achieves this:

Objective-C
```Objective-C
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
  if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown
     && motion == UIEventSubtypeMotionShake) 
  {
    NSLog(@"shaking!");
    SlackReporter *mediator = [SlackReporter sharedInstance];
    mediator.defaultToken = @"XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    [[SlackReporter sharedInstance] displaySlackReporterWithForms:nil initialTitle:nil];
  }
}
```

Swift
```Swift
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if UIDevice.currentDevice().orientation == .PortraitUpsideDown &&
           motion == .MotionShake
            {
                print("shaking!")
                let slackReporter = SlackReporter.sharedInstance()
                slackReporter.defaultToken = "XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
                slackReporter.displaySlackReporterWithForms(nil, initialTitle:nil)
        }
    }
  ```

Replace XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX with a Slack web-hook ID (if you don't know what Slack is and/or don't know what a Slack webhook is, read see below). 

And that's it. You're done.

## New to Slack?
Slack is a business messaging service, which allows team members to post Twitter like messages to Channels. If you aren't aware of Slack already, it's the new "next big thing" (and we say that without having any affiliation with the company). Amongst other advantages Slack provides an excellent and easy to set-up mechanism for obtaining beta-user feedback. To set-up a Slack account visit:

https://slack.com/

After you have set up a Slack Reporter account, to enable SlackReporter feedback to be posted into one of your Slack channels, create an *Incoming Webhook* for the channel. You can do that here:

https://slack.com/signin?redir=%2Fservices%2Fnew%2Fincoming-webhook%2F

## Other options for invoking forms
At Radical Fraction, we use the default feedback forms as they are without further customisation. However we have set-up a separate Slack Webhook for each of the three forms.

I use three Slack incoming webhooks ("incoming" relative to your Slack account), one for each of the three default feedback forms built into SlackReporter, so for Radical Fraction's Bead calculator app, the integration looks like this (with the actual webhook ID's redacted of course:

Objective-C
```Objective-C
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake) {
        SlackReporter *reporter = [SlackReporter sharedInstance];
        reporter.defaultToken = @"XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
        NSArray *forms = [SRForm defaultForms];
        SRForm *form = forms[0];
        form.token = @"XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
        form = forms[1];
        form.token = @"XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
        form = forms[2];
        form.token = @"XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
        [[SlackReporter sharedInstance] displaySlackReporterWithForms:forms initialTitle:nil];
    }
}
```
If you would like your users to have a more explicit means to invoke a form, you can ask SlackReporter to vend a SlackReporter UIButton widget or a SlackReporter UIBarButtonItem widget and implement these in your Toolbar. (Note in the current pre 1.0 Slack Reporter, the form definitions stored in the button widgets do not survive survive being archived and de-archived - so you will need to generate a new instance of the form buttons if your app awakes from background. If you use the default form definitions or customise the default definitions in the SlackReporter source code, this problem is avoided)

## Define your own forms
Defining your own forms is easy. Every form is comprised of at least three object types.
- SRForm, is the form itself and represents a form presented by a single table view.
- One or more SRSection objects. SRSection used to represent UITableView sections.
- One or more SRElement objects per section. SRElement is used to represent an individual feedback field and may represent one of several different form controls such as SingleLineTextField, MultiLineTextField, Email, or a List Selector. 

For clear examples of how to define forms, "func problemReportForm()->SRForm" in SRForm.swift

Objective-C
```Objective-C
    SlackReporter *reporter = [SlackReporter sharedInstance];
    // Sets a default or fallback Slack incoming webhook ID
    reporter.serviceHookID = @"XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    
    // Forms reflect the structure of iOS table views, with forms (tableView),
    // elements (section) and elements (items).
    // Every form requires a form object, allocated to the form object one or
    // more section objects and allocated to the section objects, one or more
    // element objects.
    
    // It's easier to define a form in reverse order, starting with the
    // elements in a section, followed by the section/s, followed by the
    // form itself.

    // Define form elements thusly:
    // the identifier cannot be nil, and is used to disambiguate
    // elements with the same title. Whether the identifier is displayed
    // in the Slack message is configurable in the form object. See
    // below.
    // For most cases it is only necessary to define the identifier and
    // not also a title.
    // Feedback values are required for SRFeedbackTypeListSelection
    // elements.
    
    SRFormElement *f1s1e1 = [[SRFormElement alloc]
                             initWithIdentifier:        @"Preference" // Slack feedback
                             title:                     @"Preference"
                             type:                      SRFeedbackTypeListSelection
                             feedbackValues:            @[@"Dog", @"Cat"] // For selection lists pass in an array of strings
                             rememberResult:            YES];

    SRFormElement *f1s1e2 = [[SRFormElement alloc]
                             initWithIdentifier:        @"Pet Name"
                             title:                     @"Pet Name"
                             type:                      SRFeedbackTypeSingleLineText
                             feedbackValues:            nil
                             rememberResult:            NO];
    
    // A form section has a title that appears above a group of
    // form elements (see iPhone settings section for examples.
    // In addition to the section elements, a section can also
    // have a footer, which is a good place to put text explaining
    // what is expected of the user.
    
    SRFormSection *f1s1   = [[SRFormSection alloc] initWithTitle:       @"Pet Preference"
                                                   elements:            @[f1s1e1, f1s1e2]
                                                   footerText:          @"Let us know what kind of a person you are." ];

    SRForm *form                = [[SRForm alloc] initWithTitle:            @"Pet Preference"
                                                  sections:                 @[f1s1]
                                                  systemFeedbackElements:   nil];

    [[SlackReporter sharedInstance] displaySlackReporterWithForms:@[form] initialTitle:nil];
```

## Roadmap
- OAuth2 user login and authentication. Slack Reporter is currently designed to allow un-authenticated users to post feedback regarding beta tests. This is fine for smaller groups (as beta tests tend to be). All reporting is done over TLS connections and Webhook ID's are not sent in the clear. However there is no getting around the fact if there is no sign-in machanism, a determined hacker can extract the webhook ID's. In practice, for the average beta-test, spammers are highly unlikely to bother (or at least no more likely to bother than hackers are currently bothered to target existing crash reporting services which also rely on common pre-authenticated tokens). Spammers, after all, rely on a broad range of targets to make their activity worthwhile and if your webhooks are ever compromised, you can, of course, switch them off.
- Slack bot integration
- Screen capture
- Future versions of Slack reporter will ensure webhook ID's are obsfuscated in the application binary blob (which is, of course, insufficient to deter determined hackers)
- Improved separation of concerns. Currently the SRWebServiceClient class is doing too much and SlackReporter can provide quite a useful model project if there is a better separation of concerns in this class. Ideally there will be a facade that takes Slack specific datatypes and an agent for posting JSON generic datatypes to generic services.  

## Important limitations
- While we will try not to change things uneccessarily, until version 1.0 is released there is no guarantee the SlackReporter API "contract" will be honoured.
- This pre-release version of SlackReporter while being used by Radical Fraction (and is performing very well), until we reach version 1.0 it should probably only used for smaller controlled beta tests.


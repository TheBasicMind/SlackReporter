//
//  ViewController.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 01/21/2016.
//  Copyright (c) 2016 Paul Lancefield. All rights reserved.
//

import UIKit
import SlackReporter

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if UIDevice.currentDevice().orientation == .PortraitUpsideDown &&
           motion == .MotionShake
        {
            print("shaking!")
            let slackReporter = SlackReporter.sharedInstance()
            slackReporter.defaultToken = "XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
            slackReporter.displaySlackReporterWithForms(nil, initialTitle:nil)
            let forms = SRForm.defaultForms()
            var form = forms[0]
            form.token = "XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
            form = forms[1]
            form.token = "XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
            form = forms[2]
            form.token = "XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
            slackReporter.displaySlackReporterWithForms(forms, initialTitle:nil)
        }
    }
}


//
//  SlackWebServiceClientTests.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 09/01/2016.
//  //  Copyright © 2016 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import XCTest
@testable import SlackReporter

/**
 No mock objects for Swift
 so we create mask objects to test
 individual instance methods by subclassing
 and stubbing out methods unsuitable for unit
 test
*/
class Reach_tester : Reach
{
    override func connectionStatus() -> ReachabilityStatus
    {
        return .Online(.WiFi)
    }
    
    override func monitorReachabilityChanges()
    {
        // Ensure nothing is done
    }
}


class SRWebServiceClient_Tester: SRWebServiceClient
{
    var testRequest: NSMutableURLRequest? = nil
    var dataTask: NSURLSessionDataTask? = nil
    var testData: NSData? = nil
    private var reachabilityAgent: Reach_tester
    private var uploadState: UploadState
    
    override init()
    {
        reachabilityAgent = Reach_tester()
        uploadState = .NoUploadRequired
    }
    
    override func postSlackCommand(command: SlackCommand)
    {
        do {
            try testRequest = command.URLRequest()
        }
        catch
        {
            print("Could not make URL request")
            return
        }
    }
    
    override func writeDataToDisk(data: NSData, fileCachePath: String)
    {
        testData = data
    }
    
    override func dataFromDisk(filePath: String ) throws -> NSData?
    {
        var data:NSData? = nil
        do { try data = NSJSONSerialization.dataWithJSONObject([ [ "serviceID", ["cat" : "meow'"], "ChannelID", "Text" ] ], options: .PrettyPrinted) }
        catch { }
        return data
    }
}


class SlackWebServiceClientTests: XCTestCase
{
    var webServiceClient = SRWebServiceClient_Tester()
    
    override func setUp()
    {
        super.setUp()
        webServiceClient.defaultToken = "ADefaultToken"

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        webServiceClient.testRequest = nil
        webServiceClient.dataTask = nil
        webServiceClient.testData = nil
    }
    
    
    func test_cacheJSONFormsArrayToDisk()
    {
        /////////
        /////////
        ///
        /// Data
        
        let JSON = [ [ "serviceID", ["dog" : "woof'"] ] ]

        ///////////
        ///////////
        ///
        /// Process
        
        do { try webServiceClient.cacheJSONFormsArrayToDisk(JSON) }
        catch { XCTFail("caching data to disk should not throw up an error") ; true }
        
        //////////
        //////////
        ///
        /// Result
        
        XCTAssertTrue(webServiceClient.testData != nil, "Data should be stored against the webservice client test object")
    }

    func test_retreiveJSONDataFromDisk()
    {
        /////////
        /////////
        ///
        /// Data
        
        // see above - override func dataFromDisk(filePath: String ) throws -> NSData? 
        var testData: NSData? = nil
        
        ///////////
        ///////////
        ///
        /// Process
        
        do { try testData = webServiceClient.dataFromDisk("filepath") }
        catch { XCTFail("retreiving data from disk should not throw an error") ; return }
        
        //////////
        //////////
        ///
        /// Result
        
        XCTAssertNotNil(testData, "Data should be stored against the webservice client test object")
        var array: NSArray? = nil // start nil to check value is assigned
        guard testData != nil else { XCTFail("Test data must not be nil"); return }
        do { try array = NSJSONSerialization.JSONObjectWithData( testData!, options: .MutableContainers) as? NSArray }
        catch { XCTAssert(false, "retreiving data from disk should not throw an error") ; return}
        XCTAssertTrue(NSJSONSerialization.isValidJSONObject(array!))
    }
    
    
    func test_postSlackMessageWithToken()
    {
        /////////
        /////////
        ///
        /// Data
        
        let token = "AToken"
        let channel = "AChannel"
        let text = "Some text"
        let jsonFormDict = ["a key": "a value"]
        
        ///////////
        ///////////
        ///
        /// Process
        
        // see above - override func dataFromDisk(filePath: String ) throws -> NSData?
        webServiceClient.postSlackMessageWithToken(token, channel: channel, text: text , jsonDict: jsonFormDict)
        
        //////////
        //////////
        ///
        /// Result
        
        XCTAssertNotNil(webServiceClient.testRequest, "Mutable request has been made")
        if webServiceClient.testRequest != nil {
            XCTAssertTrue(webServiceClient.testRequest!.respondsToSelector("URL") , "The web service client test rig (SRWebServiceClient_Tester) must contain a testRequest by completion of this test")
        }
    }
    
    
    func test_enqueueFormsForUpload()
    {
        /////////
        /////////
        ///
        /// Data
        
        let jsonForm = ["dog" : "woof"]
        let channel = "AChannel"
        
        ///////////
        ///////////
        ///
        /// Process
        
        do { try webServiceClient.enqueueFormForUpload(jsonForm, channel: channel) }
        catch { XCTFail("failed when method invoked with basic parameters"); return}
        
        //////////
        //////////
        ///
        /// Result
        
        XCTAssertNotNil(webServiceClient.testData, "No call made to save data to disk")
    }
    
    
    func test_enqueueFormForUpload_withFormAlreadyCachedToDisk()
    {
        ///TODO: Complete form
        
        /////////
        /////////
        ///
        /// Data
        
        ///////////
        ///////////
        ///
        /// Process
        
        //////////
        //////////
        ///
        /// Result
    }
    
    
    func test_enqueueFormForUpload_noTokensSupplied()
    {
        /////////
        /////////
        ///
        /// Data
        
        let jsonForm = ["dog" : "woof"]
        let channel = "AChannel"

        ///////////
        ///////////
        ///
        /// Process
        
        do { try webServiceClient.enqueueFormForUpload(jsonForm, channel: channel) }
        catch { XCTFail("failed when method invoked with basic parameters"); return}
        
        //////////
        //////////
        ///
        /// Result
        XCTAssertNotNil(webServiceClient.testData, "No call made to save data to disk")
        
        var array: [ [ AnyObject ] ]? = nil // start nil to check value is assigned
        do { try array = NSJSONSerialization.JSONObjectWithData( webServiceClient.testData!, options: .MutableContainers) as? [ [ AnyObject ] ] }
        catch { XCTAssertNotNil(array, "retreiving data from disk should not throw an error") ; return}
        
        guard array != nil else { XCTFail() ; return }
        guard array!.count > 1 else { XCTFail() ; return }
        guard array![1].count != 0 else { XCTFail() ; return }
        guard array![1][0] is String else { XCTFail() ; return }
        
        let serviceHookID = (array![1][0]) as! String
        XCTAssertTrue( serviceHookID == "ADefaultToken")
    }
    
}

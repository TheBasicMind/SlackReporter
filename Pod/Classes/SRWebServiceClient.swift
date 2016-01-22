//
//  SRWebServiceClient.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 02/01/2016.
//  Copyright © 2016 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import Foundation

enum SRError: ErrorType {
    case InvalidURLComponent
    case TokenNotDefined
    case InvalidTokenForCommandType
    case AuthenticatedCommandTypeRequiresAChannelArgument
    case InvalidRequestParameter
    case CouldNotParseJSON
    case ProblemWithServerResponse(Int)
    case CouldNotLoadJSONFromDisk
    case CouldNotSaveJSONToDisk
    case NoInternetConnection
}

/**
 The web service class for queuing and posting feedback to Slack.
 
 In this version we have a simple retry strategy that has no requirement for
 integrating background processing callbacks. If there are any upload failures, 
 or if network availability status changes or if the user calls this method again
 we restart processing from the queue. The queue is cached to disk to minimise 
 the chance of feedback getting lost.
*/
class SRWebServiceClient
{
    enum UploadState
    {
        case NoUploadRequired
        case RetryUpload
    }
    enum SystemFieldLocation
    {
        case First
        case Last
    }
    var defaultToken: String = ""
    var userName: String = ""
    var postAsUser: Bool = true
    var disableQueue : Bool = false
    private let reachabilityAgent: Reach
    private var uploadState: UploadState
    var fileCachePath: String
    
    
    init() {
        reachabilityAgent       = Reach()
        reachabilityAgent.monitorReachabilityChanges()
        uploadState             = .NoUploadRequired
        let path                = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        fileCachePath           = "\(path)/com.slackreporter.JSONFormsCache"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityWasChanged:", name: SRReachabilityStatusChangedNotification, object: nil)
    }
    
    /**
     The main method call for using this class to post forms to a Slack bot or custom
     integration. Takes a collection object representing the value of the Slack
     attachments argument (meeting HTTP RPC-style methods) and adds it to a file
     system cached queue.
     
     If the token property (the authentication token) is not set when this method is called,
     an error will be thrown. To post to a named channel using the channel argument, the
     intermediary needs to be a bot, or Slack custom integration.
     
     After the user exits the app, this method is called again when the SlackReporter is
     first instantiated.
     
     - parameter forms: an array of form responses to be sent to posted to Slack. If this
     parameter is nil, then we check if there are any cached forms waiting for upload and
     subject to network connectivity, process them.
     
     - parameter channel: May be either a channel name (including the # symbol) or a 
     channel ID.
     */
    func enqueueFormForUpload(form: [NSObject:AnyObject]?, channel : String, name: String = "" ) throws
    {
        if defaultToken.isEmpty { throw SRError.TokenNotDefined }
        do {
            try enqueueFormForUpload(form, token: "", channel: channel, name: name )
        } catch {
            throw error
        }
    }
    
    /**
     The main method call for using this class to post forms to a Slack webhook
     integration. Takes a collection object representing the value of the Slack
     attachments argument (meeting HTTP RPC-style methods) and adds it to a file
     system cached queue.
     
     If the user exits the app, this method is called again when the SlackReporter is
     first instantiated.
     
     - parameter forms: an array of form responses to be sent to posted to Slack. If this
     parameter is nil, then we check if there are any cached forms waiting for upload.
     
     - parameter token: May be either a webhookID, to post these forms to a specific
     webhook, or may be an empty string ("") to use the .
     */
    func enqueueFormForUpload(form: [NSObject:AnyObject]?, webhookID: String, name: String = "" ) throws
    {
        if webhookID.isEmpty && self.defaultToken.isEmpty { throw SRError.TokenNotDefined }
        do {
            try enqueueFormForUpload(form, token: webhookID, channel: "", name: name )
        }
        catch { throw error }
    }
    
    
    func restartUploadIfFormsAreCached()
    {
        do {
            try enqueueFormForUpload(nil, token: "")
        }
        catch
        {
            
        }
    }
    
    /**
     Takes a collection object representing the value of a Slack attachments argument - (an array of dictionaries)
     -
     */
    private func enqueueFormForUpload(      form: [ NSObject:AnyObject ]?,
                                            var token : String,
                                            var channel: String = "",
                                            var name: String = "" ) throws
    {
        token = token       != "" ? token : self.defaultToken
        let webhook         = channel == ""
        
        // Get the cached form objects
        // if any exist
        var formArray: [ [ AnyObject ] ]
        
        do {
            try  formArray = JSONFormsFromDisk() as! [ [AnyObject] ]
        } catch {
            /* nothing read from disk so create an empty array */
            formArray = []
        }
        
        // Upload forms as a value compatbile with 
        // a Slack attachements compatible collection
        var uploadForm:[ NSObject: AnyObject ] = [ : ]
        
        // Append the form to the array along with the
        // relevant service hook ID if it exists
        if !disableQueue {
            if form != nil {
                formArray.append( [token, form!, channel, name ] )
            }
            
            if formArray.count > 0 {
                token           = formArray[0][0] as! String
                uploadForm      = formArray[0][1] as! [ NSObject : AnyObject ]
                channel         = (formArray[0][2] as! String)
                name            = (formArray[0][3] as! String)
            }
            
            // If no forms were passed in and
            // no disk cached forms have been
            // retreived for upload we can just exit.
            guard formArray.count > 0 else { return }
            
            do {
                try cacheJSONFormsArrayToDisk(formArray)
            } catch {
                throw error
                // If an error is thrown here, the new form couldn't be written to disk, so we just abandon
                // by re-throwing the error.
            }
        }
        else
        {
            guard form != nil else { return }
            uploadForm = form!
        }
        
        let status = reachabilityAgent.connectionStatus()
        
        switch status {
        case .Offline:
            throw SRError.NoInternetConnection
        case .Online(ReachabilityType.WWAN):
            fallthrough
        case .Online(ReachabilityType.WiFi):
            if webhook {
                self.postSlackWebhookWithToken(token, text: "", jsonDict: uploadForm)
            } else if channel.isEmpty == false {
                self.postSlackMessageWithToken(token, channel: channel, text: name, jsonDict: uploadForm)
            } else {
                throw SRError.AuthenticatedCommandTypeRequiresAChannelArgument
            }
        default:
            break
        }
    }
    
    /**
     Create a Slack webhook command
     - parameter token: The authentication token or the webhook
     id to be used to post to Slack.
     - parameter channel: The channel to be used when posting 
     to slack. This value is ignored if the token
     is not either a user token or a bot token (e.g. begining 
     in "xox")
     */
    func postSlackWebhookWithToken(webhookID: String, text: String, jsonDict: [NSObject:AnyObject])
    {
        /* For now we are not using a session background task
        since the form content is extremely light and fast to
        transfer. However we wil switch to using a background
        session once we start to upload screenshot data */
        
        let command             = SlackWebhook(webhookID: webhookID, text: "")
        command.attachments     = [jsonDict]
        postSlackCommand(command)
    }
    
    /**
     Create a URL request with body data and assign the request 
     to a session. Throws an error if there are any failures for
     which retry later is not the answer.
     
     - parameter token: The authentication token or the webhook 
     id to be used to post to Slack.
     
     - parameter channel: The channel to be used when posting 
     to slack. This value is ignored if the token is not either 
     a user token or a bot token (e.g. begining in "xox")
     */
    func postSlackMessageWithToken(token: String, channel: String, text: String, jsonDict: [NSObject:AnyObject])
    {
        /* For now we are not using a session background task
        since the form content is extremely light and fast to
        transfer. However we wil switch to using a background
        session once we start to upload screenshot data */
        
        let command             = SlackPostMessage(token: token, channel: channel, text: text, username: userName, asUser: postAsUser )
        command.attachments     = [jsonDict]
        
        postSlackCommand(command)
    }
    
    /**
     Post the request object to Slack
    */
    func postSlackCommand(command: SlackCommand)
    {
        command.postSlackCommand() { ( commandStatus ) in
            let channel = ""
            switch commandStatus
            {
            case .InternalError(_):
                self.uploadState = .RetryUpload
            case .RequestError(_):
                self.uploadState = .RetryUpload
            case .ServerResponseError(_,_):
                self.uploadState = .RetryUpload
            case .Success(_, _, _):
                // success so we remove the most recently uploaded cached form
                //print( response )
                //print( NSString(data: data, encoding: NSUTF8StringEncoding)! )
                if !(self.disableQueue) {
                    self.removeForm(.First)
                }
                var formArray:  [ AnyObject ]
                do {
                    try  formArray = self.JSONFormsFromDisk() as! [ AnyObject ]
                } catch {
                    /* nothing read from disk so create an empty array */
                    formArray = [ [ ] ]
                }
                if formArray.count > 0 {
                    do {
                        try self.enqueueFormForUpload(nil, token: "", channel: channel, name: "" )
                    }
                    catch
                    {
                        print(error)
                    }
                }
                else {
                    self.uploadState = .NoUploadRequired
                }
            }
        }
    }
    
    
    private func removeForm(location:SystemFieldLocation)
    {
        var formArray: [ AnyObject ]
        do {
            try  formArray = JSONFormsFromDisk() as! [ AnyObject ]
        } catch {
            /* nothing read from disk so create an empty array */
            formArray = [ [] ]
        }
        if formArray.count > 0 {
            switch location {
            case .First:
                formArray.removeFirst()
            case .Last:
                formArray.removeLast()
            }
            do {
                try cacheJSONFormsArrayToDisk(formArray)
            } catch { }
        }
    }
    
    
    @objc func reachabilityWasChanged(notification: AnyObject)
    {
        do {
            // calling enqueue JSON form for upload with null values
            // will check if there is anything in the queue that needs
            // to be uploaded
            try enqueueFormForUpload(nil, token: "", channel: "", name: "" )
        }
        catch
        {
            // Only filesystem parsing errors are going to be caught
            // here in which case this is fatal. If this occurs since
            // this is a beta reporting app, we should stay silent.
        }
    }
    
    //MARK: - Local filesystem
    /*
    At some point will need to be refactored
    into its own class and placed behind an abstract
    interface (protocol)
    */
    func cacheJSONFormsArrayToDisk(form: AnyObject) throws
    {
        let data: NSData?
        do {
            let valid = NSJSONSerialization.isValidJSONObject(form)
            print("Valid JSON object: \(valid)")
            data = try NSJSONSerialization.dataWithJSONObject(form, options: .PrettyPrinted)
            writeDataToDisk(data!, fileCachePath: fileCachePath)
        }
        catch
        {
            throw SRError.CouldNotSaveJSONToDisk
        }
    }
    
    private func JSONFormsFromDisk() throws -> AnyObject
    {
        let path = fileCachePath
        let data: NSData?
        do {
            try data = dataFromDisk(path)
        }
        catch
        {
            print("Error reading file; \(error)")
            throw error
        }
        var array = []
        
        if let data = data {
            do {
                array = try (NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSArray)
            }
            catch
            {
                throw error
            }
        }
        
        return array as! [ [ AnyObject ] ]
    }
    
    //MARK: - Unit Testable
    /**
     Abstracted behind a protocol to make dependent methods unit testable
     */
    func writeDataToDisk(data: NSData, fileCachePath: String)
    {
        let success = data.writeToFile(fileCachePath, atomically: true)
        print("JSON saved to disk: \(success)")
    }
    
    /**
     Abstracted behind a protocol to make it unit testable
     */
    func dataFromDisk(filePath: String ) throws -> NSData?
    {
        return NSData(contentsOfFile: filePath)
    }
}
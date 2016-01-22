//
//  SlackCommand.swift
//  SlackReporter
//
//  Created by Paul Lancefield on 02/01/2016.
//  Copyright © 2016 Paul Lancefield. All rights reserved.
//  Released under the MIT license
//

import Foundation

let baseSlackURLWebhook     = "https://hooks.slack.com/"
let baseSlackURLWebAPI      = "https://slack.com/"
let webAPI                  = "api/"
let webhook                 = "services/"
let jsonContentType         = "application/json charset=utf-8"


enum SRCommandError: ErrorType {
    case InvalidArgumentsForCommandForType
    case SettingOptionalCommandsForTypeThatHasNone
    case InternalError
    case ArgumentsAreNotJSONCompliant
    case CouldNotParseFormData
    case CouldNotParseJSON
    case NoInternetConnection
    case CouldNotConstructHTTPRequest
    //case RequestError(request: NSURLRequest, response: NSHTTPURLResponse)
    //case ServerResponseError(request: NSURLRequest, response: NSHTTPURLResponse)
    case Success(request: NSURLRequest, response: NSHTTPURLResponse)
}


enum SRCommandStatus {
    case InternalError(SRCommandError)
    case RequestError(NSURLRequest)
    case ServerResponseError(NSURLRequest, NSHTTPURLResponse)
    case Success(NSURLRequest, NSHTTPURLResponse, NSData)
}


public enum CommandType: String
{
    case Webhook            = ""
    case Chat_postMessage   = "chat.postMessage"
    case Chat_delete        = "chat.delete"
    case Chat_update        = "chat.update"
}


public enum Arg : String
{
    case Token              = "token"
    case TimeStamp          = "ts"
    case Channel            = "channel"
    case Text               = "text"
    case Username           = "username"
    case AsUser             = "as_user"
    case Parse              = "parse"
    case LinkNames          = "link_names"
    case Attachments        = "attachments"
    case UnfurlLinks        = "unfurl_links"
    case UnfurlMedia        = "unfurl_media"
    case IconUrl            = "icon_url"
    case IconEmoji          = "icon_emoji"
}


let CommandTable: [ CommandType : (required: [Arg], optional: [Arg]? ) ] = [
    .Webhook                : ( required:   [Arg.Token],
        
                                optional:   [Arg.Attachments,
                                            Arg.Parse,
                                            Arg.LinkNames,
                                            Arg.Attachments,
                                            Arg.UnfurlLinks,
                                            Arg.UnfurlMedia,
                                            Arg.IconUrl,
                                            Arg.IconEmoji] ),
    
    .Chat_postMessage       : ( required:   [Arg.Token,
                                            Arg.Channel,
                                            Arg.Text],
        
                                optional:   [Arg.Username,
                                            Arg.AsUser,
                                            Arg.Parse,
                                            Arg.LinkNames,
                                            Arg.Attachments,
                                            Arg.UnfurlLinks,
                                            Arg.UnfurlMedia,
                                            Arg.IconUrl,
                                            Arg.IconEmoji] ),
]


public class SlackCommand
{
    private(set) var command: CommandType
    private(set) var requiredArguments: [Arg : AnyObject]
    private(set) var optionalArguments: [Arg : AnyObject] = [:]
    private(set) var compositedPayloadDictionary: [NSString : AnyObject] = [:]
    
    var token: String {
        get {
            return requiredArguments[.Token] as! String
        }
        set {
            requiredArguments[.Token] = newValue
        }
    }

    
    /**
     Create a slack command for the SRWebServiceClient. May fail and throws an error. To ensure
     successful command creation use a specific command subclass if one is available for the
     command you wish to dispatch.
     - paramter command: The command type required of the command. This value constrains which
     arguments will need to be supplied to the required parameter
     - parameter required: The required arguements supplied must match the required arguments
     expected by the SlackAPI. Initialisation fails if the supplied arguments do not match
     requirements.
     */
    init?(command aCommand: CommandType, requiredArguments: (argument: Arg, value: AnyObject)...) throws
    {
        let argStrings: [ String ]      = requiredArguments.map({ $0.argument.rawValue }).sort()
        let allowedCommands: (required: [Arg], optional: [Arg]? ) = CommandTable[aCommand]!
        let requiredCommands            = allowedCommands.required.map({ $0.rawValue }).sort()
        self.command                    = aCommand
        self.requiredArguments          = [:]
        do {
            try self.requiredArguments = SlackCommand.dictionaryForArguments( requiredArguments )
        } catch { throw SRCommandError.ArgumentsAreNotJSONCompliant }
        if argStrings.elementsEqual(requiredCommands) == false {
            throw SRCommandError.InvalidArgumentsForCommandForType
        }
    }
    
    
    private class func dictionaryForArguments(arguments: [ (argument: Arg, value: AnyObject) ] ) throws ->[ Arg : AnyObject ]
    {
        var dictionary: [Arg : AnyObject] = [:]
        var jsonDict: [String : AnyObject] = [:]
        for argumentTuple in arguments {
            let value = argumentTuple.value
            //if NSJSONSerialization.isValidJSONObject( value ) == false {
            //    throw SRCommandError.ArgumentsAreNotJSONCompliant
            //}
            dictionary[argumentTuple.argument] = value
            jsonDict[argumentTuple.argument.rawValue] = argumentTuple.value
        }
        return dictionary
    }

    
    func setOptionalArguments(arguments: (argument: Arg, value: AnyObject)...) throws
    {
        let argStrings: [ String ] = arguments.map({ $0.argument.rawValue }).sort()
        let allowedArguments: (required: [Arg], optional: [Arg]? ) = CommandTable[command]!
        guard let optionalArguments = allowedArguments.optional?.map({ $0.rawValue }).sort() else {
            throw SRCommandError.SettingOptionalCommandsForTypeThatHasNone
        }
        
        for optionalArgument in argStrings {
            if optionalArguments.contains(optionalArgument) == false {
                throw SRCommandError.InvalidArgumentsForCommandForType
            }
        }
        
        do {
            try self.optionalArguments = SlackCommand.dictionaryForArguments( arguments )
        } catch { throw error }
    }
    
    /**
     Create a URLRequest encapsulating this slack command
    */
    func URLRequest()throws -> NSMutableURLRequest
    {
        let request: NSMutableURLRequest
        var dictionary : [String: AnyObject]    = [:]
        let boundary                            = "Boundary-\(NSUUID().UUIDString)"
        let contentType                         = "multipart/form-data; boundary=\(boundary)"
        
        for (s, a) in requiredArguments {
            dictionary[s.rawValue]              = a
        }
        
        for (s, a) in optionalArguments {
            dictionary[s.rawValue]              = a
        }
        
        self.compositedPayloadDictionary = dictionary
        let data:NSData
        
        do  {
            try data = formDataWithDictionary(dictionary, boundary: boundary)
        } catch {
            // This is an error case for which retry makes no sense
            // so we remove the form from the queue and abandon
            throw SRError.CouldNotParseJSON
        }
                
        // URL of the endpoint we're going to contact.
        guard let myURL = NSURL.init(string:"\(baseSlackURLWebAPI)api/\(command.rawValue)") else
        {
            throw SRError.InvalidURLComponent
        }
        
        // Create a POST request with our JSON as a request body.
        request = NSMutableURLRequest.init(URL: myURL)
        request.HTTPMethod = "POST";
        request.setValue(contentType, forHTTPHeaderField:"Content-Type")
        request.HTTPBody = data
        
        //print( NSString(data: data, encoding: NSUTF8StringEncoding)! )
        
        return request
    }
    
    /**
     Post the request object to Slack
     */
    func postSlackCommand(completion: ( SRCommandStatus )->Void )
    {
        let request: NSMutableURLRequest
        
        do {
            try request = URLRequest()
        }
        catch
        {
            completion( SRCommandStatus.InternalError(SRCommandError.CouldNotConstructHTTPRequest) )
            return
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, httpResp, error) in
            let httpURLResp = httpResp as! NSHTTPURLResponse?
            guard error == nil else {
                // failure condition
                completion( SRCommandStatus.RequestError(request) )
                return
            }
            guard  (200..<300).contains( httpURLResp!.statusCode) else {
                // Status code in an unexpected range.
                // Something has gone awry
                completion( SRCommandStatus.ServerResponseError(request, httpURLResp!))
                return
            }
            completion( SRCommandStatus.Success(request, httpURLResp!, data!))
        }
        // Start the task
        task.resume()
    }
    
    /**
     Produces data encoded for the multi-part forms specification
     which Slack currently requires for the web API (Slack are 
     apparently switching to JSON content type soon).
     */
    func formDataWithDictionary(dictionary: [ NSString : AnyObject ], boundary: String) throws ->NSData
    {
        let httpBody            = NSMutableData()
        for (argument, value) in dictionary {
            httpBody.appendData( "--\(boundary)\r\n".dataUsingEncoding( NSUTF8StringEncoding )! )
            httpBody.appendData( "Content-Disposition: form-data; name=\"\(argument)\"\r\n\r\n".dataUsingEncoding( NSUTF8StringEncoding )! )
            switch value {
            case is Array<AnyObject>:
                fallthrough
            case is Dictionary<NSObject,AnyObject>:
                let data: NSData
                do  {
                    try data = NSJSONSerialization.dataWithJSONObject(value, options:.PrettyPrinted)
                } catch {
                    throw SRCommandError.CouldNotParseJSON
                }
                httpBody.appendData(data)
                httpBody.appendData( "\r\n".dataUsingEncoding( NSUTF8StringEncoding )! )
            case is String:
                httpBody.appendData( "\(value)\r\n".dataUsingEncoding( NSUTF8StringEncoding )! )
            default:
                httpBody.appendData( "\(value)\r\n".dataUsingEncoding( NSUTF8StringEncoding )! )
            }
        }
        httpBody.appendData("--\(boundary)--\r\n".dataUsingEncoding( NSUTF8StringEncoding )! )
        return httpBody
    }
}


public class SlackWebhook: SlackCommand
{
    private override init(command aCommand: CommandType, requiredArguments: (argument: Arg, value: AnyObject)...) {
        do {
            try super.init(command: .Webhook, requiredArguments: requiredArguments[0] )!
        }
        catch
        {
            
        }
    }
    
    
    /**
    Create a webhook command for sending some message text to slack (message text may include markup)
    */
    convenience init(webhookID token: String, text: String = "" )
    {
        self.init(command: .Webhook, requiredArguments: (argument: .Token, value: token) )
        self.optionalArguments[.Text] = text
    }
    
    
    var webhookID: String {
        get {
            return requiredArguments[.Token] as! String
        }
        set {
            requiredArguments[.Token] = newValue
        }
    }
    
    /// Only accepts the attachment if it is a valid JSON
    /// compatible object or collection.
    var attachments: AnyObject? {
        get {
            return optionalArguments[.Attachments] as AnyObject?
        }
        set {
            guard let attachments = newValue else { return }
            if NSJSONSerialization.isValidJSONObject(attachments) {
                optionalArguments[.Attachments] = attachments
            }
        }
    }
    
    /**
     Create a URLRequest encapsulating this slack command
     */
    override func URLRequest()throws -> NSMutableURLRequest
    {
        let request: NSMutableURLRequest
        var dictionary : [String: AnyObject] = [:]
        for (s, a) in requiredArguments {
            dictionary[s.rawValue] = a
        }
        for (s, a) in optionalArguments {
            dictionary[s.rawValue] = a
        }
        // Remove the token element
        let hookID = webhookID
        dictionary["token"] = nil
        
        let data:NSData
        
        do  {
            try data = NSJSONSerialization.dataWithJSONObject(dictionary, options:.PrettyPrinted)
        } catch {
            // This is an error case for which retry makes no sense
            // so we remove the form from the queue and abandon
            throw SRError.CouldNotParseJSON
        }
        
        // URL of the endpoint we're going to contact.
        
        guard let myURL = NSURL.init(string:"\(baseSlackURLWebhook)services/\(hookID)") else
        {
            throw SRError.InvalidURLComponent
        }
        
        // Create a POST request with our JSON as a request body.
        request = NSMutableURLRequest.init(URL: myURL)
        request.HTTPMethod = "POST";
        request.setValue(jsonContentType, forHTTPHeaderField:"Content-Type")
        request.HTTPBody = data
        return request
    }
}


public class SlackPostMessage : SlackCommand
{
    var channel: String {
        get {
            return requiredArguments[.Channel] as! String
        }
        set {
            requiredArguments[.Channel] = newValue
        }
    }
    var text: String {
        get {
            return requiredArguments[.Text] as! String
        }
        set {
            requiredArguments[.Text] = newValue
        }
    }
    
    /// Only accepts the attachment if it is a valid JSON
    /// compatible object or collection.
    var attachments: AnyObject? {
        get {
            return optionalArguments[.Attachments] as AnyObject?
        }
        set {
            guard let attachments = newValue else { return }
            if NSJSONSerialization.isValidJSONObject(attachments) {
                optionalArguments[.Attachments] = attachments
            }
        }
    }
    
    /**
     The specialised init interface of for the post message command.
    */
    init(token: String, channel: String, text: String = "", username: String = "", asUser: Bool = false) {
        do {
            try super.init( command: .Chat_postMessage,
                            requiredArguments:   (argument: .Token, value: token ),
                                                 (argument: .Channel, value: channel),
                                                 (argument: .Text, value: text) )!
            self.optionalArguments = [.Username: username, .AsUser : asUser]
        } catch {
            
        }
    }
    
    /**
     The specialised initialisation interface of for the post message command.
     If using this command, the default token will be supplied.
     */
    init(channel: String, text: String) {
        do {
            try super.init( command:             .Chat_postMessage,
                            requiredArguments:   (argument: .Token, value: "" ),
                                                 (argument: .Channel, value: channel),
                                                 (argument: .Text, value: text) )!
        } catch {
            
        }
    }
}











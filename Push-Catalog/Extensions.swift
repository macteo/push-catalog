//
//  Extensions.swift
//  Push-Catalog
//
//  Created by Matteo Gavagnin on 01/02/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

import UIKit

/**
 Convenience `UIMutableUserNotificationAction` to build it from a dictionary.
 */
extension UIMutableUserNotificationAction {
    convenience init?(dictionary: [String: AnyObject]) {
        self.init()
        if let _destructive = dictionary[kDestructiveKey] as? Bool {
            destructive = _destructive
        } else {
            destructive = false
        }
        
        if let secure = dictionary[kAuthenticationRequiredKey] as? Bool {
            authenticationRequired = secure
        } else {
            authenticationRequired = false
        }
        
        if let _title = dictionary[kTitleKey] as? String {
            title = _title
        } else {
            title = "Missing"
        }
        
        if let _identifier = dictionary[kIdentifierKey] as? String {
            identifier = _identifier
        } else {
            identifier = title
        }
        
        if let _behavior = dictionary[kBehaviorKey] as? String {
            if _behavior == kTextInputBehaviorKey {
                if #available(iOS 9.0, *) {
                    behavior = .TextInput
                }
            }
        }
        
        activationMode = UIUserNotificationActivationMode.Background
        if let _mode = dictionary[kActivationModeKey] as? String {
            if _mode == kActivationModeForegroundKey {
                activationMode = .Foreground
            }
        }
    }
}

/**
 Convenience `UIAlertAction` to build it from a dictionary.
 */
extension UIAlertAction {
    class func action(dictionary: [String: AnyObject]) -> UIAlertAction {
        var style = UIAlertActionStyle.Default
        if let _destructive = dictionary[kDestructiveKey] as? Bool {
            if _destructive == true {
                // it should be set as destructive, but instead they are presented in blue by the system
                // style = .Destructive
                style = .Default
            }
        }
        
        var title = "Missing title"
        if let _title = dictionary[kTitleKey] as? String {
            title = _title
        }
        
        let action = UIAlertAction(title: title, style: style, handler: { (action) -> Void in
            if let urlString = dictionary[kUrlKey] as? String,
                let url = NSURL(string: urlString) {
                    
                    let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
                    let session = NSURLSession(configuration: sessionConfiguration)
                    let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10)
                    request.HTTPMethod = "GET"
                    let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                        print(response)
                    })
                    task.resume()
                    return
            }
        })
        
        return action
    }
}
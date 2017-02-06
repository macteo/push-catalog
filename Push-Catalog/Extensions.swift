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
            isDestructive = _destructive
        } else {
            isDestructive = false
        }
        
        if let secure = dictionary[kAuthenticationRequiredKey] as? Bool {
            isAuthenticationRequired = secure
        } else {
            isAuthenticationRequired = false
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
                    behavior = .textInput
                }
            }
        }
        
        activationMode = UIUserNotificationActivationMode.background
        if let _mode = dictionary[kActivationModeKey] as? String {
            if _mode == kActivationModeForegroundKey {
                activationMode = .foreground
            }
        }
    }
}

/**
 Convenience `UIAlertAction` to build it from a dictionary.
 */
extension UIAlertAction {
    class func action(_ dictionary: [String: AnyObject]) -> UIAlertAction {
        var style = UIAlertActionStyle.default
        if let _destructive = dictionary[kDestructiveKey] as? Bool {
            if _destructive == true {
                // it should be set as destructive, but instead they are presented in blue by the system
                // style = .Destructive
                style = .default
            }
        }
        
        var title = "Missing title"
        if let _title = dictionary[kTitleKey] as? String {
            title = _title
        }
        
        let action = UIAlertAction(title: title, style: style, handler: { (action) -> Void in
            if let urlString = dictionary[kUrlKey] as? String,
                let url = URL(string: urlString) {
                    let sessionConfiguration = URLSessionConfiguration.default
                    let session = URLSession(configuration: sessionConfiguration)
                    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
                    request.httpMethod = "GET"
                    
                    let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                        print("\(response)")
                    })
                    task.resume()
                    return
            }
        })
        
        return action
    }
}

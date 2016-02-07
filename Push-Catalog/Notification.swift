//
//  Notification.swift
//  Push-Catalog
//
//  Created by Matteo Gavagnin on 01/02/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

import UIKit

let kPayloadKey                     = "payload"
let kActionsKey                     = "actions"
let kActionTitleKey                 = "title"
let kAlertKey                       = "alert"
let kTitleKey                       = "title"
let kBodyKey                        = "body"
let kSoundKey                       = "sound"
let kDefaultSoundKey                = "default"
let kBadgeKey                       = "badge"
let kActivationModeKey              = "mode"
let kActivationModeForegroundKey    = "foreground"
let kBehaviorKey                    = "behavior"
let kDestructiveKey                 = "destructive"
let kAuthenticationRequiredKey      = "secure"
let kIdentifierKey                  = "identifier"
let kTextInputBehaviorKey           = "textInput"
let kClearKey                       = "clear"
let kUrlKey                         = "url"
let kApsKey                         = "aps"
let kCategoryKey                    = "category"
let kContentAvailableKey            = "content-available"

class Notification: NSObject, NSCoding {
    let payload: [NSObject: AnyObject]
    let date: NSDate
    
    init(payload: [NSObject: AnyObject], date: NSDate) {
        self.payload = payload
        self.date = date
        super.init()
    }

    convenience required init?(coder decoder: NSCoder) {
        let payloadData = decoder.decodeObjectForKey("payload") as! NSData
        let payload = NSKeyedUnarchiver.unarchiveObjectWithData(payloadData) as! [String: AnyObject]
        let date = decoder.decodeObjectForKey("date") as! NSDate
        self.init(payload: payload, date: date)
    }
    
    func encodeWithCoder(coder: NSCoder) {
        let payloadData = NSKeyedArchiver.archivedDataWithRootObject(self.payload)
        coder.encodeObject(payloadData, forKey: "payload")
        coder.encodeObject(self.date, forKey: "date")
    }
    
    var data : NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }
    
    override var description : String {
        return "Notification \(payload)"
    }
    
    /**
     We forge an alert to be shown when you receive a push notification while
     the app is in foreground. We mimick the behavior enforced by iOS used when
     the app is in background and you choose *Alerts* as style.
     */
    func forgeAndPresentAlert() {
        guard let aps = payload[kApsKey] as? [String: AnyObject] else { return }
        
        var (title, message) = ("", "")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Open", style: .Default, handler: nil))
        if let _ = aps[kContentAvailableKey] as? Int,
            let payload = payload[kPayloadKey] as? [String: AnyObject] {
                (title, message) = titleAndMessageFromPayload()
                if let actions = payload[kActionsKey] as? [[String: AnyObject]] {
                    for action in actions {
                        let alertAction = UIAlertAction.action(action)
                        alertController.addAction(alertAction)
                    }
                }
        } else {
            (title, message) = titleAndMessageFromAps()
        }
        alertController.addAction(UIAlertAction(title: "Close", style: .Cancel, handler: nil))
        alertController.title = title
        alertController.message = message
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func titleAndMessageFromAps() -> (title: String, message: String) {
        return titleAndMessage(payload[kApsKey]?[kAlertKey])
    }
    
    func titleAndMessageFromPayload() -> (title: String, message: String) {
        return titleAndMessage(payload[kPayloadKey]?[kAlertKey])
    }
    
    /**
     Extracting alert title and (eventually) body from the notification
     dictionary to replicate the iOS behavior.
     */
    func titleAndMessage(alert: AnyObject?) -> (title: String, message: String) {
        var title = ""
        var message = ""
        
        func titleFrom(string: String) -> String {
            // Title is shown only on the Apple Watch
            var title = string
            // So we use the application name to replicate the behavior
            if let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleDisplayName") as? String {
                title = appName
            } else {
                title = "Catalog"
            }
            return title
        }
        
        if let alertTitle = alert as? String {
            title = titleFrom(alertTitle)
        } else if let alertDictionary = alert as? [String : AnyObject] {
            if let alertTitle = alertDictionary[kTitleKey] as? String {
                title = titleFrom(alertTitle)
            }
            if let alertBody = alertDictionary[kBodyKey] as? String {
                message = alertBody
            }
        }
        return (title, message)
    }
    
    /**
     Send an internal cocoa notification (`NSNotification`) to registered
     objects.
     */
    func reportNotificationReceived() {
        let internalNotification = NSNotification(name: kPushNotificationReceivedKey, object: nil, userInfo: self.payload)
        NSNotificationCenter.defaultCenter().postNotification(internalNotification)
        
        NotificationsManager.sharedInstance.receivedNewNotification(self)
    }
    
    func performAction() {
        performAction(delay: 0)
    }
    
    func performAction(delay delay: Int) {
        // Content available notifications
        if let aps = payload[kApsKey] as? [String: AnyObject],
            let _ = aps[kContentAvailableKey] as? Int {
                
            // Remove every pending local notification
            if let clear = payload[kClearKey] as? Bool {
                if clear == true {
                    UIApplication.sharedApplication().cancelAllLocalNotifications()
                    UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                }
            }
            
            // Custom category
            if let payload = payload[kPayloadKey] as? [String: AnyObject] {
                guard let categoryIdentifier = payload[kCategoryKey] as? String else { return }
                
                let category = UIMutableUserNotificationCategory()
                category.identifier = categoryIdentifier
                
                if let _actions = payload[kActionsKey] as? [[String: AnyObject]] {
                    var actions = [UIMutableUserNotificationAction]()
                    for action in _actions {
                        if let action = UIMutableUserNotificationAction(dictionary: action) {
                            actions.append(action)
                        }
                    }
                    category.setActions(actions, forContext: UIUserNotificationActionContext.Default)
                }
                
                if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                    appDelegate.registerCategory(category)
                }
                
                let localNotification = UILocalNotification()
                
                let (title, message) = titleAndMessageFromPayload()
                if #available(iOS 8.2, *) {
                    localNotification.alertTitle = title
                }
                localNotification.alertBody = message
                
                localNotification.userInfo = payload
                localNotification.category = category.identifier
                
                if let soundName = payload[kSoundKey] as? String {
                    if soundName == kDefaultSoundKey {
                        localNotification.soundName = UILocalNotificationDefaultSoundName
                    } else {
                        localNotification.soundName = soundName
                    }
                }
                
                if let badgeNumber = payload[kBadgeKey] as? Int {
                    localNotification.applicationIconBadgeNumber = badgeNumber
                }
                
                let fireDate = NSCalendar.currentCalendar().dateByAddingUnit(
                    .Second,
                    value: delay,
                    toDate: NSDate(),
                    options: NSCalendarOptions(rawValue: 0))

                localNotification.fireDate = fireDate
                
                UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            }
        }
    }
}
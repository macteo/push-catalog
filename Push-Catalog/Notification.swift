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
    let payload: [String: AnyObject]
    let date: Date
    
    init(payload: [String: AnyObject], date: Date) {
        self.payload = payload
        self.date = date
        super.init()
    }

    convenience required init?(coder decoder: NSCoder) {
        let payloadData = decoder.decodeObject(forKey: "payload") as! Data
        let payload = NSKeyedUnarchiver.unarchiveObject(with: payloadData) as! [String: AnyObject]
        let date = decoder.decodeObject(forKey: "date") as! Date
        self.init(payload: payload, date: date)
    }
    
    func encode(with coder: NSCoder) {
        let payloadData = NSKeyedArchiver.archivedData(withRootObject: self.payload)
        coder.encode(payloadData, forKey: "payload")
        coder.encode(self.date, forKey: "date")
    }
    
    var data : Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
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
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Open", style: .default, handler: nil))
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
        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        alertController.title = title
        alertController.message = message
        UIApplication.shared().keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
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
    func titleAndMessage(_ alert: AnyObject?) -> (title: String, message: String) {
        var title = ""
        var message = ""
        
        func titleFrom(_ string: String) -> String {
            // Title is shown only on the Apple Watch
            var title = string
            // So we use the application name to replicate the behavior
            if let appName = Bundle.main().objectForInfoDictionaryKey("CFBundleDisplayName") as? String {
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
        let internalNotification = Foundation.Notification(name: NSNotification.Name(rawValue: kPushNotificationReceivedKey), object: nil, userInfo: self.payload)
        NotificationCenter.default().post(internalNotification)
        
        NotificationsManager.shared.receivedNewNotification(self)
    }
    
    func performAction() {
        performAction(0)
    }
    
    func performAction(_ delay: Int) {
        // Content available notifications
        if let aps = payload[kApsKey] as? [String: AnyObject],
            let _ = aps[kContentAvailableKey] as? Int {
                
            // Remove every pending local notification
            if let clear = payload[kClearKey] as? Bool {
                if clear == true {
                    UIApplication.shared().cancelAllLocalNotifications()
                    UIApplication.shared().applicationIconBadgeNumber = 0
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
                    category.setActions(actions, for: UIUserNotificationActionContext.default)
                }
                
                if let appDelegate = UIApplication.shared().delegate as? AppDelegate {
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
                
                let fireDate = Calendar.current().date(
                    byAdding: .second,
                    value: delay,
                    to: Date(),
                    options: Calendar.Options(rawValue: 0))

                localNotification.fireDate = fireDate
                
                UIApplication.shared().scheduleLocalNotification(localNotification)
            }
        }
    }
}

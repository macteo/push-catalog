//
//  NotificationManager.swift
//  Push-Catalog
//
//  Created by Matteo Gavagnin on 01/02/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

import Foundation

class NotificationsManager {
    static let sharedInstance = NotificationsManager()
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var notifications = [Notification]()
    
    func setup() {
        if let existingNotifications = defaults.objectForKey("notifications") as? [NSData] {
            notifications = existingNotifications.map {NSKeyedUnarchiver.unarchiveObjectWithData($0) as! Notification}
            if notifications.count == 0 {
                basicNotifications()
            }
        } else {
            basicNotifications()
        }
    }
    
    func saveNotifications() {
        notifications.sortInPlace({$0.date.timeIntervalSince1970 > $1.date.timeIntervalSince1970})
        defaults.setObject(notifications.map { $0.data }, forKey: "notifications")
        defaults.synchronize()
    }
    
    func receivedNewNotification(notification: Notification) {
        notifications.insert(notification, atIndex: 0)
        saveNotifications()
    }

    func basicNotifications() {
        // TODO: load notifications from disk and generate them
        
        let fm = NSFileManager.defaultManager()
        let path = NSBundle.mainBundle().resourcePath!
        
        do {
            let items = try fm.contentsOfDirectoryAtPath(path)
            for item in items {
                if item.containsString(".json") {
                    do {
                        let path = "\(NSBundle.mainBundle().resourcePath!)/\(item)"
                        let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                        do {
                            guard let jsonResult: [NSObject : AnyObject] = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments) as? [NSObject : AnyObject] else { return }
                            let notification = Notification(payload: jsonResult, date: NSDate())
                            notifications.append(notification)
                        } catch {}
                    } catch {}
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        print("Load notifications: \(notifications)")
        saveNotifications()
    }
}
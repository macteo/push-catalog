//
//  NotificationManager.swift
//  Push-Catalog
//
//  Created by Matteo Gavagnin on 01/02/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

import Foundation

class NotificationsManager {
    static let shared = NotificationsManager()
    
    let defaults = UserDefaults.standard()
    var notifications = [Notification]()
    
    func setup() {
        if let existingNotifications = defaults.object(forKey: "notifications") as? [Data] {
            notifications = existingNotifications.map {NSKeyedUnarchiver.unarchiveObject(with: $0) as! Notification}
            if notifications.count == 0 {
                basicNotifications()
            }
        } else {
            basicNotifications()
        }
    }
    
    func saveNotifications() {
        notifications.sort(isOrderedBefore: {$0.date.timeIntervalSince1970 > $1.date.timeIntervalSince1970})
        defaults.set(notifications.map { $0.data }, forKey: "notifications")
        defaults.synchronize()
    }
    
    func receivedNewNotification(_ notification: Notification) {
        notifications.insert(notification, at: 0)
        saveNotifications()
    }

    func basicNotifications() {
        // TODO: load notifications from disk and generate them
        
        let fm = FileManager.default()
        let path = Bundle.main().resourcePath!
        
        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            for item in items {
                if item.contains(".json") {
                    do {
                        let path = "\(Bundle.main().resourcePath!)/\(item)"
                        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.dataReadingMappedIfSafe)
                        do {
                            guard let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject] else { return }
                            let notification = Notification(payload: jsonResult, date: Date())
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

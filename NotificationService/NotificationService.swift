//
//  NotificationService.swift
//  NotificationService
//
//  Created by Matteo Gavagnin on 17/06/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceiveNotificationRequest(request: UNNotificationRequest, withContentHandler contentHandler: (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            do {
                let documentsDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
                let url = documentsDirectoryURL.URLByAppendingPathComponent("icon-test.png")!
                print("Url \(url)")
                let attachment = try UNNotificationAttachment(identifier: "icon", URL: url, options: nil)

                print("Description: \(attachment.description)")
                bestAttemptContent.attachments = [attachment]
            } catch let error {
                print("Error: \(error)")
            }
            
            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

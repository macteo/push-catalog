//
//  NotificationViewController.swift
//  NotificationContent
//
//  Created by Matteo Gavagnin on 15/06/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        self.label?.text = notification.request.content.body
    }
}

//
//  ViewController.swift
//  Push-Catalog
//
//  Created by Matteo Gavagnin on 29/01/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

import UIKit

let emptyText = "Waiting for push notifications..."

class ViewController: UIViewController {
    @IBOutlet var textView: UITextView!

    @IBAction func settingsButtonPressed(sender: AnyObject) {
        if let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(settingsUrl)
        } else {
            print("Failed to generate Settings app url.")
        }
    }

    var payload : [NSObject : AnyObject]?
    var token : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.pushReceived(_:)), name: kPushNotificationReceivedKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.pushToken(_:)), name: kPushNotificationTokenKey, object: nil)
        printPayload()
    }

    func pushReceived(notification: NSNotification) {
        payload = notification.userInfo
        printPayload()
    }

    func pushToken(notification: NSNotification) {
        if let newToken = notification.object as? String {
            token = newToken
        }
    }

    func printPayload() {
        if let payload = payload {
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(payload, options: NSJSONWritingOptions.PrettyPrinted)
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    let replacedString = string.stringByReplacingOccurrencesOfString("\\/", withString: "/")
                    textView.textAlignment = .Left
                    textView.text = replacedString
                }
            } catch _ as NSError {
                textView.textAlignment = .Center
                textView.text = NSLocalizedString("Error: cannot parse the notification Payload.", comment: "")
            }
        } else {
            textView.text = emptyText
            textView.textAlignment = .Center
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @IBAction func infoButtonPressed(sender: UIBarButtonItem) {
        let shortVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String

        let appVersion = "\(shortVersion) (\(version))"
        if let token = token {
            let alertController = UIAlertController(title: NSLocalizedString("Push Catalog", comment: ""), message: String(format: "Version: %@\n\n%@", arguments: [appVersion, token]), preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Cancel, handler: { (action) -> Void in
                alertController.dismissViewControllerAnimated(true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Share APN Token", comment: ""), style: .Default, handler: { (action) -> Void in
                let activityController = UIActivityViewController(activityItems: [token], applicationActivities: nil)
                self.presentViewController(activityController, animated: true, completion: nil)
                let pasteboard = UIPasteboard.generalPasteboard()
                pasteboard.string = token
                alertController.dismissViewControllerAnimated(true, completion: nil)
            }))
            alertController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let message = String(format: "Version: %@\n\nEnable push notifications in Settings app to receive push notifications.", arguments: [appVersion])
            let alertController = UIAlertController(title: NSLocalizedString("Push Catalog", comment: ""), message: message, preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Cancel, handler: { (action) -> Void in
                alertController.dismissViewControllerAnimated(true, completion: nil)
            }))
            alertController.popoverPresentationController?.barButtonItem = sender
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}

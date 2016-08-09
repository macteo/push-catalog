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

    @IBAction func settingsButtonPressed(_ sender: AnyObject) {
        if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared().openURL(settingsUrl)
        } else {
            print("Failed to generate Settings app url.")
        }
    }

    var payload : [NSObject : AnyObject]?
    var token : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default().addObserver(self, selector: #selector(ViewController.pushReceived(_:)), name: kPushNotificationReceivedKey, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(ViewController.pushToken(_:)), name: kPushNotificationTokenKey, object: nil)
        printPayload()
    }

    func pushReceived(_ notification: Foundation.Notification) {
        payload = (notification as NSNotification).userInfo
        printPayload()
    }

    func pushToken(_ notification: Foundation.Notification) {
        if let newToken = notification.object as? String {
            token = newToken
        }
    }

    func printPayload() {
        if let payload = payload {
            do {
                let data = try JSONSerialization.data(withJSONObject: payload, options: JSONSerialization.WritingOptions.prettyPrinted)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    let replacedString = string.replacingOccurrences(of: "\\/", with: "/")
                    textView.textAlignment = .left
                    textView.text = replacedString
                }
            } catch _ as NSError {
                textView.textAlignment = .center
                textView.text = NSLocalizedString("Error: cannot parse the notification Payload.", comment: "")
            }
        } else {
            textView.text = emptyText
            textView.textAlignment = .center
        }
    }

    deinit {
        NotificationCenter.default().removeObserver(self)
    }

    @IBAction func infoButtonPressed(_ sender: UIBarButtonItem) {
        let shortVersion = Bundle.main().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let version = Bundle.main().objectForInfoDictionaryKey("CFBundleVersion") as! String

        let appVersion = "\(shortVersion) (\(version))"
        if let token = token {
            let alertController = UIAlertController(title: NSLocalizedString("Push Catalog", comment: ""), message: String(format: "Version: %@\n\n%@", arguments: [appVersion, token]), preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: { (action) -> Void in
                alertController.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Share APN Token", comment: ""), style: .default, handler: { (action) -> Void in
                let activityController = UIActivityViewController(activityItems: [token], applicationActivities: nil)
                self.present(activityController, animated: true, completion: nil)
                let pasteboard = UIPasteboard.general()
                pasteboard.string = token
                alertController.dismiss(animated: true, completion: nil)
            }))
            alertController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            self.present(alertController, animated: true, completion: nil)
        } else {
            let message = String(format: "Version: %@\n\nEnable push notifications in Settings app to receive push notifications.", arguments: [appVersion])
            let alertController = UIAlertController(title: NSLocalizedString("Push Catalog", comment: ""), message: message, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: { (action) -> Void in
                alertController.dismiss(animated: true, completion: nil)
            }))
            // TODO: add another action to open the settings app
            // TODO: in iOS 10 list the available settings
            //          getNotificationSettings
            alertController.popoverPresentationController?.barButtonItem = sender
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

//
//  AppDelegate.swift
//  Push-Catalog
//
//  Created by Matteo Gavagnin on 29/01/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

// TODO: add view controller to play the different push notifications payload as local notifications

import UIKit
import UserNotifications

let kPushNotificationTokenKey       = "pushNotificationToken"
let kPushNotificationReceivedKey    = "pushNotificationReceived"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let notificationTypes : UIUserNotificationType = [.badge, .sound, .alert]
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        application.statusBarStyle = .lightContent
        NotificationsManager.shared.setup()
        
        //  testAttachment()
        
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String : AnyObject] {
            let notification = Notification(payload: userInfo, date: Date())
            notification.reportNotificationReceived()
        }
        
        let settings = UIUserNotificationSettings(types: notificationTypes, categories: baseCategories)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (completed, error) in
                if completed {
                    print("Completed authorization")
                    UNUserNotificationCenter.current().setNotificationCategories(self.baseUserCategories)
                    
                    //                    let settings = UIUserNotificationSettings(forTypes: self.notificationTypes, categories: self.baseCategories)
                    //                    UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("Used declined push notification authorization")
                }
            })
        } else { // iOS 9 and 8
            UIApplication.shared.registerUserNotificationSettings(settings)
        } // TODO: also support iOS 7
        
        return true
    }
    
    func testAttachment() {
        let fromPath = Bundle.main.path(forResource: "icon-test", ofType: "png")!
        let fromURL = URL(fileURLWithPath: fromPath)
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let toURL = documentsDirectoryURL.appendingPathComponent("icon-test.png")
        if !FileManager.default.fileExists(atPath: toURL.path) {
            do {
                try FileManager.default.copyItem(at:fromURL, to: toURL)
            } catch let error {
                print("Copy attachment error \(error)")
            }
        }
        do {
            if #available(iOS 10.0, *) {
                let attachment = try UNNotificationAttachment(identifier: "icon", url: toURL, options: nil)
                print("Attachment created: \(attachment.description)")
            }
        } catch let error {
            print("Error: \(error)")
        }
        
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        handleAction(identifier, userInfo: userInfo, completionHandler: completionHandler)
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        handleAction(identifier, userInfo: notification.userInfo, completionHandler: completionHandler)
    }
    
    func handleAction(_ identifier: String?, userInfo: [AnyHashable : Any]?, completionHandler: @escaping () -> Void) {
        guard let identifier = identifier, let userInfo = userInfo else {
            print("Missing action identifier or action userInfo dictionary")
            completionHandler()
            return
        }
        guard let categoryDictionary = userInfo[kPayloadKey] as? [String: AnyObject],
            let actions = categoryDictionary[kActionsKey] as? [[String: AnyObject]] else {
            print("Missing \(kActionsKey) object or userInfo \(kPayloadKey)")
            completionHandler()
            return
        }
        for action in actions {
            guard let title = action[kActionTitleKey] as? String, title == identifier else { continue }
            guard let urlString = action[kUrlKey] as? String, let url = URL(string: urlString) else { continue }
                
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            request.httpMethod = "GET"
            
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                print("\(response)")
                completionHandler()
            })
            
            task.resume()
            return
        }
        completionHandler()
    }
    
    func registerCategory(_ category: UIMutableUserNotificationCategory) {
        var categories = baseCategories
        categories.insert(category)
        let settings = UIUserNotificationSettings(types: notificationTypes, categories: categories)
        UIApplication.shared.registerUserNotificationSettings(settings)
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func checkIfPushNotificationAreAuthorized() {
        let notificationTypes = UIApplication.shared.currentUserNotificationSettings
        guard let types = notificationTypes?.types else {
            print("Cannot fetch authorized push notification types")
            return
        }
        if types == UIUserNotificationType() {
            print("App is not authorized to receive push notifications")
            let alertController = UIAlertController(title: "Please authorize this app to receive Push notifications in Settings", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) -> Void in
                if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(settingsUrl)
                } else {
                    print("Failed to generate Settings app url.")
                }
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    /**
     The application failed to receive a push notification token.
     */
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Did fail to register for remote notifications with error: \(error.localizedDescription)")
    }
    
    /**
     Apple just assigned us a push notification token.
     */
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = convertDataToken(deviceToken)
        print("Got Push notification token from Apple: \(tokenString)")
        
        let internalNotification = Foundation.Notification(name: NSNotification.Name(rawValue: kPushNotificationTokenKey), object: nil)
        
        NotificationCenter.default.post(internalNotification)
        
        // We still want check if the use authorized the app to receive push notifications
        checkIfPushNotificationAreAuthorized()
    }
    
    /**
     Received a silent push notification with key *content-available*.
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let user = userInfo as? [String: AnyObject] {
            let notification = Notification(payload: user, date: Date())
            notification.performAction()
            
            // We are receiving the push notification while the application was
            // in foreground so we want to present an alert
            if UIApplication.shared.applicationState == .active {
                notification.forgeAndPresentAlert()
            }
            
            notification.reportNotificationReceived()
        } else {
            print("Cannot Convert userInfo into [String: AnyObject]")
        }
        
        completionHandler(.newData)
    }
    
    // We just received a push notification while the application was in foreground
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if let user = userInfo as? [String: AnyObject] {
            let notification = Notification(payload: user, date: Date())
            notification.forgeAndPresentAlert()
            notification.reportNotificationReceived()
        } else {
            print("Cannot Convert userInfo into [String: AnyObject]")
        }
    }

    /**
     Parsing the push notification token and converting it from `NSData` to 
     `String`.
     */
    func convertDataToken(_ dataToken: Data) -> String {
        let token = dataToken.map { String(format: "%02.2hhx", $0) }.joined()
        return token
    }
    
    /**
     Base `UIMutableUserNotificationCategory` category with Yes and No buttons.
     */
    var baseCategories : Set<UIMutableUserNotificationCategory> {
        let acceptAction = UIMutableUserNotificationAction()
        acceptAction.identifier = "YES"
        acceptAction.title = "Yes"
        acceptAction.activationMode = UIUserNotificationActivationMode.background
        acceptAction.isDestructive = false
        acceptAction.isAuthenticationRequired = false
        
        let refuseAction = UIMutableUserNotificationAction()
        refuseAction.identifier = "NO"
        refuseAction.title = "No"
        refuseAction.activationMode = UIUserNotificationActivationMode.background
        refuseAction.isDestructive = true
        refuseAction.isAuthenticationRequired = false
        
        let openOrNotCategory = UIMutableUserNotificationCategory()
        openOrNotCategory.identifier = "yesOrNo"
        openOrNotCategory.setActions([acceptAction, refuseAction], for: UIUserNotificationActionContext.default)
        
        return [openOrNotCategory]
    }
    
    @available(iOS 10.0, *)
    var baseUserCategories : Set<UNNotificationCategory> {
//        let acceptAction = UIMutableUserNotificationAction()
//        acceptAction.identifier = "YES"
//        acceptAction.title = "Yes"
//        acceptAction.activationMode = UIUserNotificationActivationMode.Background
//        acceptAction.destructive = false
//        acceptAction.authenticationRequired = false
//        
//        let refuseAction = UIMutableUserNotificationAction()
//        refuseAction.identifier = "NO"
//        refuseAction.title = "No"
//        refuseAction.activationMode = UIUserNotificationActivationMode.Background
//        refuseAction.destructive = true
//        refuseAction.authenticationRequired = false
//        
//        let openOrNotCategory = UIMutableUserNotificationCategory()
//        openOrNotCategory.identifier = "yesOrNo"
//        openOrNotCategory.setActions([acceptAction, refuseAction], forContext: UIUserNotificationActionContext.Default)
        
        let viewCategory = UNNotificationCategory(identifier: "view-category", actions: [], intentIdentifiers: [], options: [])
        return [viewCategory]
    }
}

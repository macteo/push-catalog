//
//  AppDelegate.swift
//  Push-Catalog
//
//  Created by Matteo Gavagnin on 29/01/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

// TODO: add view controller to play the different push notifications payload as local notifications

import UIKit

let kPushNotificationTokenKey       = "pushNotificationToken"
let kPushNotificationReceivedKey    = "pushNotificationReceived"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let notificationTypes : UIUserNotificationType = [.Badge, .Sound, .Alert]
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.statusBarStyle = .LightContent
        NotificationsManager.sharedInstance.setup()
        
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] {
            let notification = Notification(payload: userInfo, date: NSDate())
            notification.reportNotificationReceived()
        }
        
        let settings = UIUserNotificationSettings(forTypes: notificationTypes, categories: baseCategories)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        return true
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        handleAction(identifier, userInfo: userInfo, completionHandler: completionHandler)
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        handleAction(identifier, userInfo: notification.userInfo, completionHandler: completionHandler)
    }
    
    func handleAction(identifier: String?, userInfo: [NSObject: AnyObject]?, completionHandler: () -> Void) {
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
            guard let title = action[kActionTitleKey] as? String where title == identifier else { continue }
            guard let urlString = action[kUrlKey] as? String, let url = NSURL(string: urlString) else { continue }
                
            let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: sessionConfiguration)
            let request = NSMutableURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 10)
            request.HTTPMethod = "GET"
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                print(response)
                completionHandler()
            })
            task.resume()
            return
        }
        completionHandler()
    }
    
    func registerCategory(category: UIMutableUserNotificationCategory) {
        var categories = baseCategories
        categories.insert(category)
        let settings = UIUserNotificationSettings(forTypes: notificationTypes, categories: categories)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func checkIfPushNotificationAreAuthorized() {
        let notificationTypes = UIApplication.sharedApplication().currentUserNotificationSettings()
        guard let types = notificationTypes?.types else {
            print("Cannot fetch authorized push notification types")
            return
        }
        if types == .None {
            print("App is not authorized to receive push notifications")
            let alertController = UIAlertController(title: "Please authorize this app to receive Push notifications in Settings", message: nil, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
                if let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(settingsUrl)
                } else {
                    print("Failed to generate Settings app url.")
                }
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    /**
     The application failed to receive a push notification token.
     */
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(error.localizedDescription)
    }
    
    /**
     Apple just assigned us a push notification token.
     */
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let tokenString = convertDataToken(deviceToken)
        print("Got Push notification token from Apple: \(tokenString)")
        let internalNotification = NSNotification(name: kPushNotificationTokenKey, object: tokenString)
        NSNotificationCenter.defaultCenter().postNotification(internalNotification)
        
        // We still want check if the use authorized the app to receive push notifications
        checkIfPushNotificationAreAuthorized()
    }
    
    /**
     Received a silent push notification with key *content-available*.
     */
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        let notification = Notification(payload: userInfo, date: NSDate())
        notification.performAction()
        
        // We are receiving the push notification while the application was
        // in foreground so we want to present an alert
        if UIApplication.sharedApplication().applicationState == .Active {
            notification.forgeAndPresentAlert()
        }
        
        notification.reportNotificationReceived()
        
        completionHandler(.NewData)
    }
    
    // We just received a push notification while the application was in foreground
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        let notification = Notification(payload: userInfo, date: NSDate())
        notification.forgeAndPresentAlert()
        notification.reportNotificationReceived()
    }

    /**
     Parsing the push notification token and converting it from `NSData` to 
     `String`.
     */
    func convertDataToken(dataToken: NSData) -> String {
        let tokenString = dataToken.description.stringByReplacingOccurrencesOfString("<", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString(">", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        return tokenString
    }
    
    /**
     Base `UIMutableUserNotificationCategory` category with Yes and No buttons.
     */
    var baseCategories : Set<UIMutableUserNotificationCategory> {
        let acceptAction = UIMutableUserNotificationAction()
        acceptAction.identifier = "YES"
        acceptAction.title = "Yes"
        acceptAction.activationMode = UIUserNotificationActivationMode.Background
        acceptAction.destructive = false
        acceptAction.authenticationRequired = false
        
        let refuseAction = UIMutableUserNotificationAction()
        refuseAction.identifier = "NO"
        refuseAction.title = "No"
        refuseAction.activationMode = UIUserNotificationActivationMode.Background
        refuseAction.destructive = true
        refuseAction.authenticationRequired = false
        
        let openOrNotCategory = UIMutableUserNotificationCategory()
        openOrNotCategory.identifier = "yesOrNo"
        openOrNotCategory.setActions([acceptAction, refuseAction], forContext: UIUserNotificationActionContext.Default)
        
        return [openOrNotCategory]
    }
}
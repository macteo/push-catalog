//
//  NotificationService.m
//  ObjService
//
//  Created by Matteo Gavagnin on 17/06/16.
//  Copyright © 2016 Dolomate. All rights reserved.
//

#import "NotificationService.h"
#import <UIKit/UIKit.h>

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
//    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains: NSUserDomainMask];
//    NSURL *documentFolderURL = urls[0];
//    NSURL *fileURL = [documentFolderURL URLByAppendingPathComponent:@"icon-test.png"];
//    
//    NSLog(@"Url %@", fileURL.absoluteString);
//
//    NSURL *url = [NSURL URLWithString: @"https://macteo.it/img/macteo.jpg"];
    
    UNNotificationAction *yesAction = [UNNotificationAction actionWithIdentifier:@"YES" title:@"Yes" options:UNNotificationActionOptionNone];
    UNNotificationAction *noAction = [UNNotificationAction actionWithIdentifier:@"NO" title:@"No" options:UNNotificationActionOptionNone];
    UNNotificationAction *maybeAction = [UNNotificationAction actionWithIdentifier:@"MAYBE" title:@"Maybe" options:UNNotificationActionOptionNone];
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"yesOrNo" actions:@[yesAction, noAction, maybeAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    
//    acceptAction.identifier = "YES"
//    acceptAction.title = "Yes"
//    acceptAction.activationMode = UIUserNotificationActivationMode.background
//    acceptAction.isDestructive = false
//    acceptAction.isAuthenticationRequired = false
//    
//    let refuseAction = UIMutableUserNotificationAction()
//    refuseAction.identifier = "NO"
//    refuseAction.title = "No"
//    refuseAction.activationMode = UIUserNotificationActivationMode.background
//    refuseAction.isDestructive = true
//    refuseAction.isAuthenticationRequired = false
//    
//    let openOrNotCategory = UIMutableUserNotificationCategory()
//    openOrNotCategory.identifier = "yesOrNo"
//    openOrNotCategory.setActions([acceptAction, refuseAction], for: UIUserNotificationActionContext.default)
    
//     return [openOrNotCategory]

    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithObjects:category, nil]];
    
    self.bestAttemptContent.categoryIdentifier = @"yesOrNo";
    self.contentHandler(self.bestAttemptContent);
    
//    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
//                                             dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//                                                 
//                                                 [data writeToURL:fileURL atomically:true];
//                                                
//                                                 
//                                                 NSError *errorAttachment;
//                                                 
//                                                 UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"icon" URL:fileURL options:nil error:&errorAttachment];
//                                                 
//                                                 
//                                                 if (attachment != nil) {
//                                                     self.bestAttemptContent.attachments = @[attachment];
//                                                 } else {
//                                                     NSLog(@"Attachment creation error %@", error);
//                                                 }
//                                                 
//                                                 self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
//                                                 
//                                                 self.contentHandler(self.bestAttemptContent);
//                                             }];
//    
//    [downloadTask resume];
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end

//
//  LZPushManager.m
//
//  Created by lzw on 15/5/25.
//  Copyright (c) 2015年 lzw. All rights reserved.
//

#import "LZPushManager.h"

@implementation LZPushManager

+ (LZPushManager *)manager {
    static LZPushManager *pushManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pushManager = [[LZPushManager alloc] init];
    });
    return pushManager;
}

- (void)registerForRemoteNotification {
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert |
                                                UIUserNotificationTypeBadge |
                                                UIUserNotificationTypeSound
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else {
        [application registerForRemoteNotificationTypes:
         UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeAlert |
         UIRemoteNotificationTypeSound];
    }
}

- (void)saveInstallationWithDeviceToken:(NSData *)deviceToken {
    AVInstallation *currentInstallation = [AVInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    // openClient 的时候也会将 clientId 注册到 channels，这里多余了？
    [currentInstallation addUniqueObject:[AVUser currentUser].objectId forKey:kAVIMInstallationKeyChannels];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)unsubscribeCurrentUserChannelWithBlock:(AVBooleanResultBlock)block {
    if ([AVUser currentUser].objectId) {
        [AVPush unsubscribeFromChannelInBackground:[AVUser currentUser].objectId block:block];
    }
}

- (void)pushMessage:(NSString *)message userIds:(NSArray *)userIds block:(AVBooleanResultBlock)block {
    AVPush *push = [[AVPush alloc] init];
    [push setChannels:userIds];
    [push setMessage:message];
    [push sendPushInBackgroundWithBlock:block];
}

- (void)cleanBadge {
    UIApplication *application = [UIApplication sharedApplication];
    NSInteger num = application.applicationIconBadgeNumber;
    if (num != 0) {
        AVInstallation *currentInstallation = [AVInstallation currentInstallation];
        [currentInstallation setBadge:0];
        [currentInstallation saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
            NSLog(@"%@", error ? error : @"succeed");
        }];
        application.applicationIconBadgeNumber = 0;
    }
    [application cancelAllLocalNotifications];
}

- (void)syncBadge {
    AVInstallation *currentInstallation = [AVInstallation currentInstallation];
    if (currentInstallation.badge != [UIApplication sharedApplication].applicationIconBadgeNumber) {
        [currentInstallation setBadge:[UIApplication sharedApplication].applicationIconBadgeNumber];
        [currentInstallation saveEventually: ^(BOOL succeeded, NSError *error) {
            NSLog(@"%@", error ? error : @"succeed");
        }];
    } else {
//        NSLog(@"badge not changed");
    }
}

@end

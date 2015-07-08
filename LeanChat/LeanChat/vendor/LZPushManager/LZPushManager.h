//
//  LZPushManager.h
//
//  Created by lzw on 15/5/25.
//  Copyright (c) 2015年 lzw. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>

static NSString *const kAVIMInstallationKeyUserId = @"userId";

@interface LZPushManager : NSObject

+ (LZPushManager *)manager;

// please call in application:didFinishLaunchingWithOptions:launchOptions
- (void)registerForRemoteNotification;

// please call in application:didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
- (void)saveInstallationWithDeviceToken:(NSData *)deviceToken;

// push message
- (void)pushMessage:(NSString *)message userIds:(NSArray *)userIds block:(AVBooleanResultBlock)block;

// please call in applicationDidBecomeActive:application
- (void)cleanBadge;

//save the local applicationIconBadgeNumber to the server
- (void)syncBadge;

@end

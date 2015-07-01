//
//  CDAppDelegate.m
//  LeanChat
//
//  Created by Qihe Bian on 7/23/14.
//  Copyright (c) 2014 LeanCloud. All rights reserved.
//

#import "CDAppDelegate.h"
#import "CDCommon.h"
#import "CDLoginVC.h"
#import "CDBaseTabC.h"
#import "CDBaseNavC.h"
#import "CDConvsVC.h"
#import "CDFriendListVC.h"
#import "CDProfileVC.h"
#import "CDAbuseReport.h"
#import "CDCacheManager.h"

#import "CDUtils.h"
#import "CDAddRequest.h"
#import "CDIMService.h"
#import "LZPushManager.h"

@implementation CDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [CDAddRequest registerSubclass];
    [CDAbuseReport registerSubclass];
#if USE_US
    [AVOSCloud useAVCloudUS];
#endif
    [AVOSCloud setApplicationId:AVOSAppID clientKey:AVOSAppKey];
    //    [AVOSCloud setApplicationId:CloudAppId clientKey:CloudAppKey];
    //    [AVOSCloud setApplicationId:PublicAppId clientKey:PublicAppKey];
    [AVAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    if (SYSTEM_VERSION >= 7.0) {
        [[UINavigationBar appearance] setBarTintColor:NAVIGATION_COLOR];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    }
    else {
        [[UINavigationBar appearance] setTintColor:NAVIGATION_COLOR];
    }
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor whiteColor], NSForegroundColorAttributeName, [UIFont boldSystemFontOfSize:17], NSFontAttributeName, nil]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    if ([AVUser currentUser]) {
        [self toMain];
    }
    else {
        [self toLogin];
    }
    
    [[LZPushManager manager] registerForRemoteNotification];
    
#ifdef DEBUG
    [AVPush setProductionMode:NO];  // 如果要测试申请好友是否有推送，请设置为 YES
    [AVAnalytics setAnalyticsEnabled:NO];
    [AVOSCloud setAllLogsEnabled:YES];
#endif
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[LZPushManager manager] cleanBadge];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[LZPushManager manager] saveInstallationWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    DLog(@"%@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (application.applicationState == UIApplicationStateActive) {
        // 应用在前台时收到推送，只能来自于普通的推送，而非离线消息推送
    }
    else {
        [AVAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    DLog(@"receiveRemoteNotification");
}

- (void)toLogin {
    CDLoginVC *controller = [[CDLoginVC alloc] init];
    self.window.rootViewController = controller;
}

- (void)addItemController:(UIViewController *)itemController toTabBarController:(CDBaseTabC *)tab {
    CDBaseNavC *nav = [[CDBaseNavC alloc] initWithRootViewController:itemController];
    [tab addChildViewController:nav];
}

- (void)toMain{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    AVUser *user = [AVUser currentUser];
    [[CDCacheManager manager] registerUser:user];
    WEAKSELF
    [CDChatManager manager].userDelegate = [CDIMService service];
    [[CDChatManager manager] openWithClientId:user.objectId callback: ^(BOOL succeeded, NSError *error) {
        DLog(@"%@", error);
        CDBaseTabC *tab = [[CDBaseTabC alloc] init];
        [weakSelf addItemController:[[CDConvsVC alloc] init] toTabBarController:tab];
        [weakSelf addItemController:[[CDFriendListVC alloc] init] toTabBarController:tab];
        [weakSelf addItemController:[[CDProfileVC alloc] init] toTabBarController:tab];
        
        tab.selectedIndex = 0;
        weakSelf.window.rootViewController = tab;
    }];
}

@end

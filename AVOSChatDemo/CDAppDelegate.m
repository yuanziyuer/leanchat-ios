//
//  CDAppDelegate.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/23/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDAppDelegate.h"
#import "CDCommon.h"
#import "CDLoginVC.h"
#import "CDBaseTabC.h"
#import "CDBaseNavC.h"
#import "CDChatListVC.h"
#import "CDFriendListVC.h"
#import "CDProfileVC.h"
#import "CDModels.h"
#import "CDService.h"

@implementation CDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [CDAddRequest registerSubclass];
#if USE_US
    [AVOSCloud useAVCloudUS];
#endif
    [AVOSCloud setApplicationId:AVOSAppID clientKey:AVOSAppKey];
//    [AVOSCloud setApplicationId:PublicAppId clientKey:PublicAppKey];
    [AVAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    if (SYSTEM_VERSION >= 7.0) {
        [[UINavigationBar appearance] setBarTintColor:NAVIGATION_COLOR];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        //[UINavigationBar appearance].opaque = YES;
        //[UINavigationBar appearance].translucent=YES;
    } else {
        [[UINavigationBar appearance] setTintColor:NAVIGATION_COLOR];
    }
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor whiteColor], NSForegroundColorAttributeName, [UIFont boldSystemFontOfSize:17], NSFontAttributeName, nil]];
    if ([AVUser currentUser]) {
        [self toMain];
    } else {
        [self toLogin];
    }
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]==NO) {
        [application registerForRemoteNotificationTypes:
         UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeAlert |
         UIRemoteNotificationTypeSound];
    } else {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
#ifdef DEBUG
    [AVAnalytics setAnalyticsEnabled:NO];
    [AVOSCloud setVerbosePolicy:kAVVerboseShow];
    [AVLogger addLoggerDomain:AVLoggerDomainIM];
    [AVLogger addLoggerDomain:AVLoggerDomainCURL];
    [AVLogger setLoggerLevelMask:AVLoggerLevelAll];
#endif
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application{
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSInteger num=application.applicationIconBadgeNumber;
    if(num!=0){
        AVInstallation *currentInstallation = [AVInstallation currentInstallation];
        [currentInstallation setBadge:0];
        [currentInstallation saveEventually:^(BOOL succeeded, NSError *error) {
            DLog(@"%@" ,error? error:@"succeed");
        }];
        application.applicationIconBadgeNumber=0;
    }
    [application cancelAllLocalNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    AVInstallation *currentInstallation = [AVInstallation currentInstallation];
    if(currentInstallation.deviceToken==nil){
        //first time register
        [currentInstallation setDeviceTokenFromData:deviceToken];
        [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            DLog(@"%@",error);
        }];
    }else{
        DLog(@"have registered");
    }
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    DLog(@"%@",error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    //可选 通过统计功能追踪通过提醒打开应用的行为
    if (application.applicationState == UIApplicationStateActive) {
        // 转换成一个本地通知，显示到通知栏，你也可以直接显示出一个alertView，只是那样稍显aggressive：）
//        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//        localNotification.userInfo = userInfo;
//        localNotification.soundName = UILocalNotificationDefaultSoundName;
//        localNotification.alertBody = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
//        localNotification.fireDate = [NSDate date];
//        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    } else {
        [AVAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    
    DLog(@"receiveRemoteNotification");
    //这儿你可以加入自己的代码 根据推送的数据进行相应处理
}

- (void)toLogin {
    CDLoginVC *controller = [[CDLoginVC alloc] init];
    self.window.rootViewController = controller;
}

-(void)addItemController:(UIViewController*)itemController toTabBarController:(CDBaseTabC*)tab{
    CDBaseNavC* nav=[[CDBaseNavC alloc] initWithRootViewController:itemController];
    [tab addChildViewController:nav];
}

- (void)toMain {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    CDIM* client=[CDIM sharedInstance];
    [client open];
    AVUser* user=[AVUser currentUser];
    [CDCache registerUser:user];
    CDStorage* storage=[CDStorage sharedInstance];
    [storage setupWithUserId:user.objectId];
    
    CDBaseTabC *tab = [[CDBaseTabC alloc] init];
    
    [self addItemController:[[CDChatListVC alloc] init] toTabBarController:tab];
    [self addItemController:[[CDFriendListVC alloc] init] toTabBarController:tab];
    [self addItemController:[[CDProfileVC alloc] init] toTabBarController:tab];
    
    tab.selectedIndex=0;
    
    self.window.rootViewController = tab;
    
//    AVInstallation* installation=[AVInstallation currentInstallation];
//    AVUser* user=[AVUser currentUser];
//    [user setObject:installation forKey:INSTALLATION];
//    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if(error){
//            [CDUtils logError:error callback:nil];
//        }else{
//        }
//    }];
}

@end

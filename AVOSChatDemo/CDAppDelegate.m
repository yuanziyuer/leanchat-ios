//
//  CDAppDelegate.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/23/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDAppDelegate.h"
#import "CDCommon.h"
#import "CDLoginController.h"
#import "CDBaseTabBarController.h"
#import "CDBaseNavigationController.h"
#import "CDChatListController.h"
#import "CDContactListController.h"
#import "CDProfileController.h"
#import "CDSessionManager.h"
#import "CDChatGroup.h"
#import "CDUpgradeService.h"
#import "CDUtils.h"
#import "CDEmotionUtils.h"
#import "CDCacheService.h"
#import "CDDatabaseService.h"
#import "CDModels.h"
#import "CDIM.h"

@implementation CDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [CDAddRequest registerSubclass];
    [CDChatGroup registerSubclass];
    [CDSetting registerSubclass];
#if USE_US
    [AVOSCloud useAVCloudUS];
#endif
    [AVOSCloud setApplicationId:AVOSAppID clientKey:AVOSAppKey];
//    [AVOSCloud setApplicationId:PublicAppId clientKey:PublicAppKey];
    //统计应用启动情况
    [AVAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    if (SYSTEM_VERSION >= 7.0) {
        [[UINavigationBar appearance] setBarTintColor:NAVIGATION_COLOR];
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
//        [UINavigationBar appearance].opaque = YES;
//        [[UINavigationBar appearance] setTranslucent:YES];
    } else {
        [[UINavigationBar appearance] setTintColor:NAVIGATION_COLOR];
    }
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor whiteColor], NSForegroundColorAttributeName, [UIFont boldSystemFontOfSize:17], NSFontAttributeName, nil]];
    UIViewController* nextController;
    if ([AVUser currentUser]) {
        nextController=[self toMain];
    } else {
        nextController=[self toLogin];
    }
    [self splashScreenAtAnchorView:nextController];
    
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
    if(CD_DEBUG){
       setenv("LOG_CURL", "YES", 0);
       setenv("LOG_IM", "YES", 0);
       [AVOSCloud setVerbosePolicy:kAVVerboseShow];
       [AVAnalytics setAnalyticsEnabled:NO];
       [AVLogger addLoggerDomain:AVLoggerDomainIM];
       [AVLogger setLoggerLevelMask:AVLoggerLevelAll];        
    }
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    int num=application.applicationIconBadgeNumber;
    if(num!=0){
        AVInstallation *currentInstallation = [AVInstallation currentInstallation];
        [currentInstallation setBadge:0];
        [currentInstallation saveEventually];
        application.applicationIconBadgeNumber=0;
    }
    [application cancelAllLocalNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    //推送功能打开时, 注册当前的设备, 同时记录用户活跃, 方便进行有针对的推送
    NSLog(@"didRegister");
    AVInstallation *currentInstallation = [AVInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    
    //可选 通过统计功能追踪打开提醒失败, 或者用户不授权本应用推送
    //[AVAnalytics event:@"开启推送失败" label:[error description]];
    NSLog(@"error=%@",[error description]);
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
    
    NSLog(@"receiveRemoteNotification");
    //这儿你可以加入自己的代码 根据推送的数据进行相应处理
}

- (UIViewController*)toLogin {
    CDLoginController *controller = [[CDLoginController alloc] init];
    self.window.rootViewController = controller;
    return controller;
}

-(void)addItemController:(UIViewController*)itemController toTabBarController:(CDBaseTabBarController*)tab{
    CDBaseNavigationController* nav=[[CDBaseNavigationController alloc] initWithRootViewController:itemController];
    [tab addChildViewController:nav];
}

- (UIViewController*)toMain {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    CDBaseTabBarController *tab = [[CDBaseTabBarController alloc] init];
    
    [self addItemController:[[CDChatListController alloc] init] toTabBarController:tab];
    [self addItemController:[[CDContactListController alloc] init] toTabBarController:tab];
    [self addItemController:[[CDProfileController alloc] init] toTabBarController:tab];
    
    tab.selectedIndex=1;
    
    self.window.rootViewController = tab;
    
//    [CDUpgradeService upgradeWithBlock:^(BOOL upgrade, NSString *oldVersion, NSString *newVersion) {
//        if(upgrade && [newVersion isEqualToString:@"1.0.8"]){
//            [CDDatabaseService upgradeToAddField];
//        }
//    }];
    [CDCacheService registerUser:[AVUser currentUser]];
//    AVInstallation* installation=[AVInstallation currentInstallation];
//    AVUser* user=[AVUser currentUser];
//    [user setObject:installation forKey:INSTALLATION];
//    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if(error){
//            [CDUtils logError:error callback:nil];
//        }else{
//        }
//    }];

    // important
//    [CDGroupService findGroupsWithCallback:^(NSArray *objects, NSError *error) {
//        [CDUtils logError:error callback:^{
//            for(CDChatGroup* group in objects){
//                [CDGroupService setDelegateWithGroupId:group.objectId];
//            }
//        }];
//    } cacheFirst:YES];
    
    CDIM* client=[CDIM sharedInstance];
    [client open];
    

    return tab;
}

-(void)splashScreenAtAnchorView:(UIViewController*)anchorController{
    UIImageView *imgv = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIImage* image=[UIImage imageNamed:@"splash.png"];
    imgv.image=image;
    imgv.contentMode=UIViewContentModeScaleAspectFill;
    imgv.userInteractionEnabled = YES;
    [anchorController.view addSubview:imgv];

    double duration=0.5;
    double delay=2;
    if(CD_DEBUG){
        duration=0;
        delay=0;
    }
    [UIView animateWithDuration:duration delay:delay options:0
                     animations:^{
                         imgv.alpha=0.0f;
                     } completion:^(BOOL finished){
                         [imgv removeFromSuperview];
                     }];
    [self.window addSubview:anchorController.view];
}

- (void)removeSplash:(UIImageView *)imageView {
    [imageView removeFromSuperview];
}

@end

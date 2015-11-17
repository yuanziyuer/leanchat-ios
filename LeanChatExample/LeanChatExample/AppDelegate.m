//
//  AppDelegate.m
//  LeanChatExample
//
//  Created by lzw on 15/4/3.
//  Copyright (c) 2015年 avoscloud. All rights reserved.
//

#import "AppDelegate.h"
#import "CDUserFactory.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [AVOSCloud setApplicationId:@"xcalhck83o10dntwh8ft3z5kvv0xc25p6t3jqbe5zlkkdsib" clientKey:@"m9fzwse7od89gvcnk1dmdq4huprjvghjtiug1u2zu073zn99"];
    [CDChatManager manager].userDelegate = [[CDUserFactory alloc] init];
    
#ifdef DEBUG
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
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end

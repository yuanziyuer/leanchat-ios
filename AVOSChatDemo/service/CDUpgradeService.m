//
//  CDUpgradeService.m
//  LeanChat
//
//  Created by lzw on 14/11/28.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDUpgradeService.h"
#define CD_VERSION @"version"
#import "AFNetworking.h"

@implementation CDUpgradeService

+(NSString*)currentVersion{
    NSString* versionStr=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return versionStr;
}

+(void)upgradeWithBlock:(CDUpgradeBlock)callback{
    NSUserDefaults* defaults=[NSUserDefaults standardUserDefaults];
    NSString* version=[defaults objectForKey:CD_VERSION];
    NSString* curVersion=[CDUpgradeService currentVersion];
    BOOL upgrade=[version compare:curVersion options:NSNumericSearch]==NSOrderedAscending;
    callback(upgrade,version,curVersion);
    [defaults setObject:curVersion forKey:CD_VERSION];
}

@end

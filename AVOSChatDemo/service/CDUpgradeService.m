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

+(void)findNewVersionWithBlock:(AVBooleanResultBlock)block{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString* url=@"http://fir.im/api/v2/app/version/54735a3a50954b4a19005430?token=4X9h0nA3fuWynm5bmTFOZrjmeic27wBLGO12egYB";
    [manager GET:url parameters:@{} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* dict=(NSDictionary*)responseObject;
        NSString* version=dict[@"versionShort"];
        //version=@"1.2.1";
        NSString* curVersion=[[self class] currentVersion];
        BOOL remoteNew=[curVersion compare:version options:NSNumericSearch]==NSOrderedAscending;
        block(remoteNew,nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        block(NO,error);
    }];
}

@end

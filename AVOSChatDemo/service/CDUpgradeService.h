//
//  CDUpgradeService.h
//  LeanChat
//
//  Created by lzw on 14/11/28.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

typedef void (^CDUpgradeBlock)(BOOL upgrade,NSString* oldVersion,NSString* newVersion);

@interface CDUpgradeService : NSObject

+(NSString*)currentVersion;

+(void)upgradeWithBlock:(CDUpgradeBlock)callback;


@end

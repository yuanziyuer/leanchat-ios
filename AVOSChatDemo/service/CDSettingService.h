//
//  CDSettingService.h
//  LeanChat
//
//  Created by lzw on 15/1/15.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDModels.h"

@interface CDSettingService : NSObject

+(void)getSettingWithBlock:(AVIdResultBlock)block;

+(void)changeSetting:(CDSetting*)setting msgPush:(BOOL)msgPush sound:(BOOL)sound block:(AVIdResultBlock)block;


@end

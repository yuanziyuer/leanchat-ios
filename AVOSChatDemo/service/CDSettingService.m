//
//  CDSettingService.m
//  LeanChat
//
//  Created by lzw on 15/1/15.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDSettingService.h"
#import "CDUtils.h"

@implementation CDSettingService

+(void)getSettingWithBlock:(AVIdResultBlock)block{
    AVUser* user=[AVUser currentUser];
    [user fetchInBackgroundWithKeys:@[SETTING] block:^(AVObject *object, NSError *error) {
        if(error){
            block(nil,error);
        }else{
            CDSetting* setting=[user objectForKey:SETTING];
            block(setting,nil);
        }
    }];
}

+(CDSetting*)createSettingAndBind:(NSError**)error{
    CDSetting* setting=[[CDSetting alloc] init];
    setting.msgPush=YES;
    setting.sound=YES;
    [setting save:error];
    if(*error==nil){
        AVUser* user=[AVUser currentUser];
        [user setObject:setting forKey:SETTING];
        [user save:error];
    }
    return setting;
}

+(void)changeSetting:(CDSetting*)setting msgPush:(BOOL)msgPush sound:(BOOL)sound block:(AVIdResultBlock)block{
    [CDUtils runInGlobalQueue:^{
        NSError* error;
        CDSetting* newSetting=setting;
        if(newSetting==nil){
            newSetting=[self createSettingAndBind:&error];
        }
        if(error){
            block(nil,error);
        }else{
            [newSetting setObject:[NSNumber numberWithBool:msgPush] forKey:MSG_PUSH];
            [newSetting setObject:[NSNumber numberWithBool:sound] forKey:SOUND];
            [newSetting save:&error];
        }
        [CDUtils runInMainQueue:^{
            block(newSetting,error);
        }];
    }];
}

@end

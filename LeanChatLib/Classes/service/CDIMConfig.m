//
//  CDIMConfig.m
//  LeanChatLib
//
//  Created by lzw on 15/4/8.
//  Copyright (c) 2015年 avoscloud. All rights reserved.
//

#import "CDIMConfig.h"

@implementation CDIMConfig

+(CDIMConfig*)config{
    static CDIMConfig* imConfig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imConfig=[[CDIMConfig alloc] init];
    });
    return imConfig;
}

@end

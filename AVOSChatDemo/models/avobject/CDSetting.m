//
//  CDSetting.m
//  LeanChat
//
//  Created by lzw on 15/1/15.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDSetting.h"

@implementation CDSetting

@dynamic msgPush;

@dynamic sound;

+(NSString*)parseClassName{
    return @"Setting";
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

@end

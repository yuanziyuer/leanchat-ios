//
//  CDLocalService.m
//  LeanChat
//
//  Created by lzw on 15/1/16.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDLocalService.h"

#define KEY_ADD_REQUEST_N @"addRequestN"

static NSUserDefaults* userDefaults;

@implementation CDLocalService


+ (void)initialize
{
    userDefaults=[NSUserDefaults standardUserDefaults];
}

+(int)getAddRequestN{
    return [userDefaults integerForKey:KEY_ADD_REQUEST_N];
}

+(void)setAddRequestN:(int)n{
    [userDefaults setObject:@(n) forKey:KEY_ADD_REQUEST_N];
    [userDefaults synchronize];
}

@end

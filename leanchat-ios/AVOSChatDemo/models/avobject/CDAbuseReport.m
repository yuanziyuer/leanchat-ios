//
//  CDAbuseReport.m
//  LeanChat
//
//  Created by lzw on 15/4/29.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDAbuseReport.h"

@implementation CDAbuseReport

@dynamic reason;
@dynamic author;
@dynamic convid;

+(NSString*)parseClassName{
    return @"AbuseReport";
}

@end

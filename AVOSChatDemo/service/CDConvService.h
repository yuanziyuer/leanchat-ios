//
//  CDConvUtils.h
//  LeanChat
//
//  Created by lzw on 15/1/27.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"

#define CONV_TYPE @"type"
#define CONV_ATTR_TYPE_KEY @"attr.type"
#define CONV_MEMBERS_KEY @"m"

@interface CDConvService : NSObject

typedef enum : NSUInteger {
    CDConvTypeSingle = 0,
    CDConvTypeGroup,
} CDConvType;

+(CDConvType)typeOfConv:(AVIMConversation*)conv;

+(NSString*)otherIdOfConv:(AVIMConversation*)conv;

+(NSString*)nameOfConv:(AVIMConversation*)conv;

+(NSString*)nameOfUserIds:(NSArray*)userIds;

+(NSString*)titleOfConv:(AVIMConversation*)conv;

@end

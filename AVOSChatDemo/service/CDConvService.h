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

@interface CDConvService : NSObject

typedef enum : NSUInteger {
    CDConvTypeSingle = 0,
    CDConvTypeGroup,
} CDConvType;

+(CDConvType)typeOfConv:(AVIMConversation*)conv;

+(NSString*)otherIdOfConv:(AVIMConversation*)conv;

+(NSString*)nameOfConv:(AVIMConversation*)conv;

@end

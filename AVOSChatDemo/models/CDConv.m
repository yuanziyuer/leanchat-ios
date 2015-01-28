//
//  CDConvUtils.m
//  LeanChat
//
//  Created by lzw on 15/1/27.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDConv.h"

@implementation CDConv

+(CDConvType)typeOfConv:(AVIMConversation*)conv{
    CDConvType type=[[conv.attributes objectForKey:CONV_TYPE] intValue];
    if(type==CDConvTypeSingle && conv.members.count!=2){
        [NSException raise:@"invalid conv type" format:nil];
    }
    return type;
}

@end

//
//  CDConvUtils.m
//  LeanChat
//
//  Created by lzw on 15/1/27.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDConvService.h"
#import "CDCache.h"

@implementation CDConvService

+(CDConvType)typeOfConv:(AVIMConversation*)conv{
    CDConvType type=[[conv.attributes objectForKey:CONV_TYPE] intValue];
    return type;
}

+(NSString*)nameOfConv:(AVIMConversation*)conv{
    if(conv.name!=nil){
        return conv.name;
    }else{
        if([self typeOfConv:conv]==CDConvTypeSingle){
            NSString* otherId=[self otherIdOfConv:conv];
            AVUser* other=[CDCache lookupUser:otherId];
            return other.username;
        }else{
            NSMutableArray* names=[NSMutableArray array];
            for(int i=0;i<conv.members.count;i++){
                AVUser* user=[CDCache lookupUser:conv.members[i]];
                [names addObject:user.username];
            }
            return [names componentsJoinedByString:@","];
        }
    }
}

+(NSString*)otherIdOfConv:(AVIMConversation*)conv{
    NSArray* members=conv.members;
    if(members.count!=2){
        [NSException raise:@"invalid conv" format:nil];
    }
    AVUser* user=[AVUser currentUser];
    if([members containsObject:user.objectId]==NO){
        [NSException raise:@"invalid conv" format:nil];
    }
    NSString* otherId;
    if([members[0] isEqualToString:user.objectId]){
        otherId=members[1];
    }else{
        otherId=members[0];
    }
    return otherId;
}

@end

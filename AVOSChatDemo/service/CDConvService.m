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

+(NSString*)nameOfUserIds:(NSArray*)userIds{
    NSMutableArray* names=[NSMutableArray array];
    for(int i=0;i<userIds.count;i++){
        AVUser* user=[CDCache lookupUser:[userIds objectAtIndex:i]];
        [names addObject:user.username];
    }
    return [names componentsJoinedByString:@","];
}

+(NSString*)nameOfConv:(AVIMConversation*)conv{
    if([self typeOfConv:conv]==CDConvTypeSingle){
        NSString* otherId=[self otherIdOfConv:conv];
        AVUser* other=[CDCache lookupUser:otherId];
        return other.username;
    }else{
        return conv.name;
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

+(NSString*)titleOfConv:(AVIMConversation*)conv{
    if([[self class] typeOfConv:conv]==CDConvTypeSingle){
        return [self nameOfConv:conv];
    }else{
        return [NSString stringWithFormat:@"%@(%ld)",conv.name,(long)conv.members.count];
    }
}

@end

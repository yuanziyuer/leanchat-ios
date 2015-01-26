//
//  CDIMUtils.m
//  LeanChat
//
//  Created by lzw on 15/1/26.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDIMUtils.h"

@implementation CDIMUtils

+(NSString*)getOtherIdOfConv:(AVIMConversation*)conv{
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

+(NSString*)getMsgDesc:(AVIMTypedMessage*)msg{
    NSString* desc;
    AVIMLocationMessage* locationMsg;
    switch (msg.mediaType) {
        case kAVIMMessageMediaTypeText:
            desc=msg.text;
            break;
        case kAVIMMessageMediaTypeAudio:
            desc=@"声音";
            break;
        case kAVIMMessageMediaTypeImage:
            desc=@"图片";
            break;
        case kAVIMMessageMediaTypeLocation:
            locationMsg=(AVIMLocationMessage*)msg;
            desc=locationMsg.text;
            break;
        default:
            break;
    }
    return desc;
}

@end

//
//  CDIMUtils.m
//  LeanChat
//
//  Created by lzw on 15/1/26.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDIMUtils.h"
#import "CDEmotionUtils.h"

@implementation CDIMUtils

+(NSString*)getMsgDesc:(AVIMTypedMessage*)msg{
    NSString* desc;
    AVIMLocationMessage* locationMsg;
    switch (msg.mediaType) {
        case kAVIMMessageMediaTypeText:
            desc=[CDEmotionUtils convertWithText:msg.text toEmoji:YES];;
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

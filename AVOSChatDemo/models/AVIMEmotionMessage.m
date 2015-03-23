//
//  AVIMEmotionMessage.m
//  MessageDisplayKitLeanchatExample
//
//  Created by lzw on 15/3/22.
//  Copyright (c) 2015年 iOS软件开发工程师 曾宪华 热衷于简洁的UI QQ:543413507 http://www.pailixiu.com/blog   http://www.pailixiu.com/Jack/personal. All rights reserved.
//

#import "AVIMEmotionMessage.h"

@implementation AVIMEmotionMessage

+(void)load{
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType{
    return kAVIMMessageMediaTypeEmotion;
}

@end

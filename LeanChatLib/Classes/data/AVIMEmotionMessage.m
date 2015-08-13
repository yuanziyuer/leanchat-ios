//
//  AVIMEmotionMessage.m
//  LeanChatLib
//
//  Created by lzw on 15/8/12.
//  Copyright (c) 2015年 lzwjava@LeanCloud QQ: 651142978. All rights reserved.
//

#import "AVIMEmotionMessage.h"

AVIMMessageMediaType kAVIMMessageMediaTypeEmotion = 1;

@implementation AVIMEmotionMessage

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeEmotion;
}

@end

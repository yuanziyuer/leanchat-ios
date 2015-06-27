//
//  AVIMUserInfoMessage.m
//  LeanChat
//
//  Created by lzw on 15/4/14.
//  Copyright (c) 2015年 LeanCloud. All rights reserved.
//

#import "AVIMUserInfoMessage.h"

@implementation AVIMUserInfoMessage

+ (void)load {
    [self registerSubclass];
}

- (instancetype)init {
    if ((self = [super init])) {
        self.mediaType = [[self class] classMediaType];
    }
    return self;
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeUserInfo;
}

+ (instancetype)messageWithAttributes:(NSDictionary *)attributes {
    AVIMUserInfoMessage *message = [[self alloc] init];
    message.attributes = attributes;
    return message;
}

@end

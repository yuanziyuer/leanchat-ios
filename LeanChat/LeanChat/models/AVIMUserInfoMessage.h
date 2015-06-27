//
//  AVIMUserInfoMessage.h
//  LeanChat
//
//  Created by lzw on 15/4/14.
//  Copyright (c) 2015年 LeanCloud. All rights reserved.
//

#import <AVOSCloudIM/AVOSCloudIM.h>

#define kAVIMMessageMediaTypeUserInfo 1

@interface AVIMUserInfoMessage : AVIMTypedMessage <AVIMTypedMessageSubclassing>

+ (instancetype)messageWithAttributes:(NSDictionary *)attributes;

@end

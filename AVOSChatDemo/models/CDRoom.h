//
//  ChatRoom.h
//  AVOSChatDemo
//
//  Created by lzw on 14/10/27.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"
#import "CDConvService.h"

@interface CDRoom : NSObject

@property NSString* convid;

@property AVIMConversation* conv;

@property AVIMTypedMessage* lastMsg;

@property NSInteger unreadCount;

@end


//
//  ChatRoom.h
//  AVOSChatDemo
//
//  Created by lzw on 14/10/27.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"
#import "CDMsg.h"
#import "CDChatGroup.h"

@interface CDChatRoom : NSObject

@property CDMsgRoomType roomType;
@property NSString* conversationId;

@property AVIMConversation* conversation;
@property AVUser* chatUser;

@property CDMsg* latestMsg;
@property NSInteger unreadCount;

@end

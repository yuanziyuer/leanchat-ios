//
//  ChatRoom.h
//  AVOSChatDemo
//
//  Created by lzw on 14/10/27.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Msg.h"
#import "ChatGroup.h"

@interface ChatRoom : NSObject

@property CDMsgRoomType roomType;
@property ChatGroup* chatGroup;
@property AVUser* chatUser;
@property Msg* latestMsg;

@end

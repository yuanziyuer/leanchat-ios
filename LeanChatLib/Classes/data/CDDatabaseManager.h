//
//  CDDatabaseManager.h
//  LeanChatLib
//
//  Created by lzw on 15/7/13.
//  Copyright (c) 2015年 lzwjava@LeanCloud QQ: 651142978. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloudIM/AVOSCloudIM.h>

@interface CDDatabaseManager : NSObject

+ (CDDatabaseManager *)manager;
- (void)setupManagerWithDatabasePath:(NSString *)path;

- (void )insertConversation:(AVIMConversation *)conversation;

- (void)updateUnreadCountToZeroWithConversation:(AVIMConversation *)conversation;
- (void)increaseUnreadCountWithConversation:(AVIMConversation *)conversation;
- (void)updateConversation:(AVIMConversation *)conversation mentioned:(BOOL)mentioned;
- (void)updateConversations:(NSArray *)conversations;

- (void)deleteConversation:(AVIMConversation *)conversation;

- (NSArray *)selectAllConversations;
- (BOOL)isConversationExists:(AVIMConversation *)conversation;

@end

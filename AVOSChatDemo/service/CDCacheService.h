//
//  CDCacheService.h
//  LeanChat
//
//  Created by lzw on 14/12/3.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"
#import "CDChatGroup.h"

@interface CDCacheService : NSObject

+ (void)registerUsers:(NSArray*)users;

+ (void)registerUser:(AVUser*)user;

+ (AVUser *)lookupUser:(NSString*)userId;

+(CDChatGroup*)lookupChatGroupById:(NSString*)groupId;

+(void)registerChatGroup:(CDChatGroup*)chatGroup;

+(void)cacheUsersWithIds:(NSSet*)userIds callback:(AVArrayResultBlock)callback;

+(void)cacheChatGroupsWithIds:(NSMutableSet*)groupIds withCallback:(AVArrayResultBlock)callback;

+(void)registerChatGroups:(NSArray*)chatGroups;

+(void)cacheMsgs:(NSArray*)msgs withCallback:(AVArrayResultBlock)callback;

#pragma mark - current chat group

+(void)setCurConv:(AVIMConversation*)conv;

+(AVIMConversation*)getCurConv;

+(void)refreshCurConv:(AVBooleanResultBlock)callback;

+(void)setFriends:(NSArray*)_friends;

+(NSArray*)getFriends;

+(void)cacheRooms:(NSArray*)rooms callback:(AVArrayResultBlock)callback;

@end

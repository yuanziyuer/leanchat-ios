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

+(void)cacheUsersWithIds:(NSArray*)userIds callback:(AVArrayResultBlock)callback;

+(void)cacheChatGroupsWithIds:(NSMutableSet*)groupIds withCallback:(AVArrayResultBlock)callback;

+(void)registerChatGroups:(NSArray*)chatGroups;

+(void)cacheMsgs:(NSArray*)msgs withCallback:(AVArrayResultBlock)callback;

#pragma mark - current chat group

+(void)setCurrentChatGroup:(CDChatGroup*)chatGroup;

+(CDChatGroup*)getCurrentChatGroup;

+(void)refreshCurrentChatGroup:(AVBooleanResultBlock)callback;

@end

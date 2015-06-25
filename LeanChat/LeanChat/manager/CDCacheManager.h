//
//  CDCacheService.h
//  LeanChat
//
//  Created by lzw on 14/12/3.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"

@interface CDCacheManager : NSObject

+ (instancetype)manager;

- (void)registerUser:(AVUser *)user;
- (AVUser *)lookupUser:(NSString *)userId;
- (void)registerUsers:(NSArray *)users;
- (void)cacheUsersWithIds:(NSSet *)userIds callback:(AVBooleanResultBlock)callback;

- (void)registerConv:(AVIMConversation *)conv;
- (AVIMConversation *)lookupConvById:(NSString *)convid;
- (void)cacheConvsWithIds:(NSMutableSet *)convids callback:(AVArrayResultBlock)callback;
- (void)registerConvs:(NSArray *)convs;

- (void)setCurConv:(AVIMConversation *)conv;
- (AVIMConversation *)getCurConv;
- (void)refreshCurConv:(AVBooleanResultBlock)callback;

@end

//
//  CDCacheService.m
//  LeanChat
//
//  Created by lzw on 14/12/3.
//  Copyright (c) 2014年 LeanCloud. All rights reserved.
//

#import "CDCacheManager.h"
#import "CDUtils.h"
#import "CDUserManager.h"
#import <LeanChatLib/CDChatManager.h>
#import <LeanChatLib/CDChatListVC.h>

static CDCacheManager *cacheManager;

@interface CDCacheManager ()

@property (nonatomic, strong) NSMutableDictionary *cachedConvs;
@property (nonatomic, strong) NSMutableDictionary *cachedUsers;
@property (nonatomic, strong) NSString *currentConversationId;

@end

@implementation CDCacheManager

+ (instancetype)manager {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        cacheManager = [[CDCacheManager alloc] init];
    });
    return cacheManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cachedConvs = [NSMutableDictionary dictionary];
        _cachedUsers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - user cache

- (void)registerUsers:(NSArray *)users {
    for (int i = 0; i < users.count; i++) {
        [self registerUser:[users objectAtIndex:i]];
    }
}

- (void)registerUser:(AVUser *)user {
    [self.cachedUsers setObject:user forKey:user.objectId];
}

- (AVUser *)lookupUser:(NSString *)userId {
    return [self.cachedUsers valueForKey:userId];
}

#pragma mark - group cache

- (AVIMConversation *)lookupConvById:(NSString *)convid {
    return [self.cachedConvs valueForKey:convid];
}

- (void)registerConv:(AVIMConversation *)conv {
    [self.cachedConvs setObject:conv forKey:conv.conversationId];
}

- (void)registerConvs:(NSArray *)convs {
    for (AVIMConversation *conv in convs) {
        [self registerConv:conv];
    }
}

- (void)cacheConvsWithIds:(NSMutableSet *)convids callback:(AVArrayResultBlock)callback {
    NSMutableSet *uncacheConvids = [[NSMutableSet alloc] init];
    for (NSString *convid in convids) {
        if ([self lookupConvById:convid] == nil) {
            [uncacheConvids addObject:convid];
        }
    }
    [[CDChatManager manager] fetchConvsWithConvids:uncacheConvids callback: ^(NSArray *objects, NSError *error) {
        if (error) {
            callback(nil, error);
        } else {
            for (AVIMConversation *conv in objects) {
                [self registerConv:conv];
            }
            callback(objects, error);
        }
    }];
}

- (void)cacheUsersWithIds:(NSSet *)userIds callback:(AVBooleanResultBlock)callback {
    NSMutableSet *uncachedUserIds = [[NSMutableSet alloc] init];
    for (NSString *userId in userIds) {
        if ([[CDCacheManager manager] lookupUser:userId] == nil) {
            [uncachedUserIds addObject:userId];
        }
    }
    if ([uncachedUserIds count] > 0) {
        [[CDUserManager manager]findUsersByIds:[[NSMutableArray alloc] initWithArray:[uncachedUserIds allObjects]] callback: ^(NSArray *objects, NSError *error) {
            if (objects) {
                [[CDCacheManager manager] registerUsers:objects];
            }
            callback(YES, error);
        }];
    }
    else {
        callback(YES, nil);
    }
}

#pragma mark - current cache group

- (void)setCurConv:(AVIMConversation *)conv {
    [self registerConv:conv];
    self.currentConversationId = conv.conversationId;
}

- (AVIMConversation *)getCurConv {
    return [self lookupConvById:self.currentConversationId];
}

- (void)refreshCurConv:(AVBooleanResultBlock)callback {
    if ([self getCurConv] != nil) {
        [[CDChatManager manager] fecthConvWithConvid:[self getCurConv].conversationId callback: ^(AVIMConversation *conversation, NSError *error) {
            if (error) {
                callback(NO, error);
            }
            else {
                [self setCurConv:conversation];
                [[NSNotificationCenter defaultCenter] postNotificationName:kCDNotificationConversationUpdated object:nil];
                callback(YES, nil);
            }
        }];
    }
    else {
        callback(NO, [NSError errorWithDomain:nil code:0 userInfo:@{ NSLocalizedDescriptionKey:@"current conv is nil" }]);
    }
}


@end

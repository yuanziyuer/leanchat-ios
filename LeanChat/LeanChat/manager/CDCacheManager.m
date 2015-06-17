//
//  CDCacheService.m
//  LeanChat
//
//  Created by lzw on 14/12/3.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDCacheManager.h"
#import "CDUtils.h"
#import "CDUserManager.h"
#import <LeanChatLib/CDRoom.h>
#import <LeanChatLib/CDIM.h>

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
    [[CDIM sharedInstance] fetchConvsWithConvids:uncacheConvids callback: ^(NSArray *objects, NSError *error) {
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
        [[CDIM sharedInstance] fecthConvWithConvid:[self getCurConv].conversationId callback: ^(AVIMConversation *conversation, NSError *error) {
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

#pragma mark - rooms

- (void)cacheAndFillRooms:(NSMutableArray *)rooms callback:(AVBooleanResultBlock)callback {
    NSMutableSet *convids = [NSMutableSet set];
    for (CDRoom *room in rooms) {
        [convids addObject:room.convid];
    }
    [[CDCacheManager manager] cacheConvsWithIds:convids callback: ^(NSArray *objects, NSError *error) {
        if (error) {
            callback(NO, error);
        }
        else {
            for (CDRoom *room in rooms) {
                room.conv = [[CDCacheManager manager] lookupConvById:room.convid];
                if (room.conv == nil) {
                    [NSException raise:@"not found conv" format:nil];
                }
            }
            NSMutableSet *userIds = [NSMutableSet set];
            for (CDRoom *room in rooms) {
                if (room.conv.type == CDConvTypeSingle) {
                    [userIds addObject:room.conv.otherId];
                }
            }
            [[CDCacheManager manager] cacheUsersWithIds:userIds callback:callback];
        }
    }];
}

@end

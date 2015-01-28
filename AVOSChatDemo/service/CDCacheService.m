//
//  CDCacheService.m
//  LeanChat
//
//  Created by lzw on 14/12/3.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDCacheService.h"
#import "CDGroupService.h"
#import "CDMsg.h"
#import "CDUtils.h"
#import "CDService.h"

@implementation CDCacheService

static NSMutableDictionary *cachedChatGroups;
static NSMutableDictionary *cachedUsers;
static AVIMConversation* curConv;
static NSArray* friends;

+(void)initialize{
    [super initialize];
    cachedChatGroups=[[NSMutableDictionary alloc] init];
    cachedUsers=[[NSMutableDictionary alloc] init];
}

#pragma mark - user cache

+ (void)registerUsers:(NSArray*)users{
    for(int i=0;i<users.count;i++){
        [self registerUser:[users objectAtIndex:i]];
    }
}

+(void) registerUser:(AVUser*)user{
    [cachedUsers setObject:user forKey:user.objectId];
}

+(AVUser *)lookupUser:(NSString*)userId{
    return [cachedUsers valueForKey:userId];
}

#pragma mark - group cache

+(CDChatGroup*)lookupChatGroupById:(NSString*)groupId{
    return [cachedChatGroups valueForKey:groupId];
}

+(void)registerChatGroup:(CDChatGroup*)chatGroup{
    [cachedChatGroups setObject:chatGroup forKey:chatGroup.objectId];
}

+(void)registerChatGroups:(NSArray*)chatGroups{
    for(CDChatGroup* chatGroup in chatGroups){
        [self registerChatGroup:chatGroup];
    }
}

+(void)notifyGroupUpdate{
    [CDUtils postNotification:NOTIFICATION_GROUP_UPDATED];
}

+(void)cacheChatGroupsWithIds:(NSMutableSet*)groupIds withCallback:(AVArrayResultBlock)callback{
    NSMutableSet* uncacheGroupIds=[[NSMutableSet alloc] init];
    for(NSString * groupId in groupIds){
        if([self lookupChatGroupById:groupId]==nil){
            [uncacheGroupIds addObject:groupId];
        }
    }
    if([uncacheGroupIds count]>0){
        [CDGroupService findGroupsByIds:uncacheGroupIds withCallback:^(NSArray *objects, NSError *error) {
            [CDUtils filterError:error callback:^{
                for(CDChatGroup* chatGroup in objects){
                    [self registerChatGroup:chatGroup];
                }
                callback(objects,error);
            }];
        }];
    }else{
        callback([[NSMutableArray alloc] init],nil);
    }
}

+(void)cacheUsersWithIds:(NSSet*)userIds callback:(AVArrayResultBlock)callback{
    NSMutableSet* uncachedUserIds=[[NSMutableSet alloc] init];
    for(NSString* userId in userIds){
        if([self lookupUser:userId]==nil){
            [uncachedUserIds addObject:userId];
        }
    }
    if([uncachedUserIds count]>0){
        [CDUserService findUsersByIds:[[NSMutableArray alloc] initWithArray:[uncachedUserIds allObjects]] callback:^(NSArray *objects, NSError *error) {
            if(objects){
                [self registerUsers:objects];
            }
            callback(objects,error);
        }];
    }else{
        callback([[NSMutableArray alloc] init],nil);
    }
}

+(void)cacheMsgs:(NSArray*)msgs withCallback:(AVArrayResultBlock)callback{
    NSMutableSet* userIds=[[NSMutableSet alloc] init];
    NSMutableSet* groupIds=[[NSMutableSet alloc] init];
    for(CDMsg* msg in msgs){
        if(msg.roomType==CDConvTypeSingle){
            [userIds addObject:msg.fromPeerId];
            [userIds addObject:msg.toPeerId];
        }else{
            [userIds addObject:msg.fromPeerId];
            [groupIds addObject:msg.convid];
        }
    }
    [self cacheUsersWithIds:userIds callback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(objects,error);
        }else{
            [self cacheChatGroupsWithIds:groupIds withCallback:callback];
        }
    }];
}

#pragma mark - current cache group

+(void)setCurConv:(AVIMConversation*)conv{
    curConv=conv;
}

+(AVIMConversation*)getCurConv{
    return curConv;
}

+(void)refreshCurConv:(AVBooleanResultBlock)callback{
    if(curConv!=nil){
        CDIM* im=[CDIM sharedInstance];
        [im setTypeOfConv:curConv callback:^(BOOL succeeded, NSError *error) {
            if(error){
                callback(NO,error);
            }else{
                callback(YES,nil);
            }
        }];
    }else{
        callback(NO,[NSError errorWithDomain:nil code:0 userInfo:@{NSLocalizedDescriptionKey:@"currentChatGroup is nil"}]);
    }
}

#pragma mark - friends

+(void)setFriends:(NSArray*)_friends{
    friends=_friends;
}

+(NSArray*)getFriends{
    return friends;
}

#pragma mark - rooms

+(void)cacheRooms:(NSArray*)rooms callback:(AVArrayResultBlock)callback{
    NSMutableSet* userIds=[NSMutableSet set];
    for(CDRoom* room in rooms){
        if(room.type==CDConvTypeSingle){
            if([CDCacheService lookupUser:room.otherId]==nil){
                [userIds addObject:room.otherId];
            }
        }
    }
    [CDCacheService cacheUsersWithIds:userIds callback:callback];
}

@end

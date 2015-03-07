//
//  UserService.h
//  AVOSChatDemo
//
//  Created by lzw on 14-10-22.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"

@interface CDUserService : NSObject

+(void)findFriendsIsNetworkOnly:(BOOL)networkOnly callback:(AVArrayResultBlock)block;

+(void)findFriendsWithCallback:(AVArrayResultBlock)callback;

+(void)findUsersByPartname:(NSString*)partName withBlock:(AVArrayResultBlock)block;

+(NSString*)getPeerIdOfUser:(AVUser*)user;

+(void)findUsersByIds:(NSArray*)userIds callback:(AVArrayResultBlock)callback;

+(void)displayAvatarOfUser:(AVUser*)user avatarView:(UIImageView*)avatarView;

+(UIImage*)getAvatarOfUser:(AVUser*)user;

+(void)saveAvatar:(UIImage*)image callback:(AVBooleanResultBlock)callback;

+(void)addFriend:(AVUser*)user callback:(AVBooleanResultBlock)callback;

+(void)removeFriend:(AVUser*)user callback:(AVBooleanResultBlock)callback;

@end

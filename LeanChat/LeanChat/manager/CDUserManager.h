//
//  UserService.h
//  LeanChat
//
//  Created by lzw on 14-10-22.
//  Copyright (c) 2014年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"
#import "CDAddRequest.h"
#import "CDAbuseReport.h"

@interface CDUserManager : NSObject

+ (instancetype)manager;

- (void)findFriendsWithBlock:(AVArrayResultBlock)block;
- (void)isMyFriend:(AVUser *)user block:(AVBooleanResultBlock)block;

- (void)findUsersByPartname:(NSString *)partName withBlock:(AVArrayResultBlock)block;
- (NSString *)getPeerIdOfUser:(AVUser *)user;
- (void)findUsersByIds:(NSArray *)userIds callback:(AVArrayResultBlock)callback;

- (void)getBigAvatarImageOfUser:(AVUser *)user block:(void (^)(UIImage *image))block;
- (void)displayAvatarOfUser:(AVUser *)user avatarView:(UIImageView *)avatarView;
- (void)getAvatarImageOfUser:(AVUser *)user block:(void (^)(UIImage *image))block;
- (void)saveAvatar:(UIImage *)image callback:(AVBooleanResultBlock)callback;
- (void)updateUsername:(NSString *)username block:(AVBooleanResultBlock)block;

- (void)addFriend:(AVUser *)user callback:(AVBooleanResultBlock)callback;
- (void)removeFriend:(AVUser *)user callback:(AVBooleanResultBlock)callback;

- (void)countAddRequestsWithBlock:(AVIntegerResultBlock)block;
- (void)findAddRequestsWithBlock:(AVArrayResultBlock)block;
- (void)agreeAddRequest:(CDAddRequest *)addRequest callback:(AVBooleanResultBlock)callback;
- (void)tryCreateAddRequestWithToUser:(AVUser *)user callback:(AVBooleanResultBlock)callback;

- (void)reportAbuseWithReason:(NSString *)reason convid:(NSString *)convid block:(AVBooleanResultBlock)block;

@end

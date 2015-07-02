//
//  CDIMService.m
//  LeanChat
//
//  Created by lzw on 15/4/3.
//  Copyright (c) 2015年 LeanCloud. All rights reserved.
//

#import "CDIMService.h"
#import "CDCacheManager.h"
#import "CDUtils.h"
#import "CDUserManager.h"
#import "CDConvDetailVC.h"
#import "CDUser.h"
#import "CDChatVC.h"

@interface CDIMService ()

@end

@implementation CDIMService

+ (instancetype)service {
    static CDIMService *imService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imService = [[CDIMService alloc] init];
    });
    return imService;
}

#pragma mark - user delegate

- (void)cacheUserByIds:(NSSet *)userIds block:(AVBooleanResultBlock)block {
    [[CDCacheManager manager] cacheUsersWithIds:userIds callback:block];
}

- (id <CDUserModel> )getUserById:(NSString *)userId {
    CDUser *user = [[CDUser alloc] init];
    AVUser *avUser = [[CDCacheManager manager] lookupUser:userId];
    if (user == nil) {
        [NSException raise:@"user is nil" format:nil];
    }
    user.userId = userId;
    user.username = avUser.username;
    AVFile *avatarFile = [avUser objectForKey:@"avatar"];
    user.avatarUrl = avatarFile.url;
    return user;
}

- (void)goWithConv:(AVIMConversation *)conv fromNav:(UINavigationController *)nav {
    [nav popToRootViewControllerAnimated:NO];
    CDChatVC *chatVC = [[CDChatVC alloc] initWithConv:conv];
    chatVC.hidesBottomBarWhenPushed = YES;
    [nav pushViewController:chatVC animated:YES];
}

- (void)goWithUserId:(NSString *)userId fromVC:(CDBaseVC *)vc {
    [[CDChatManager manager] fetchConvWithOtherId:userId callback: ^(AVIMConversation *conversation, NSError *error) {
        if ([vc filterError:error]) {
            [self goWithConv:conversation fromNav:vc.navigationController];
        }
    }];
}

@end

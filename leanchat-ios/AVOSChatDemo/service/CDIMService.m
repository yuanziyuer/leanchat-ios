//
//  CDIMService.m
//  LeanChat
//
//  Created by lzw on 15/4/3.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDIMService.h"
#import "CDCache.h"
#import "CDUtils.h"
#import "CDUserService.h"
#import "CDConvDetailVC.h"
#import "CDUser.h"
#import "CDChatVC.h"

@interface CDIMService ()

@property (nonatomic, strong) CDIM *im;

@end

@implementation CDIMService

+ (instancetype)shareInstance {
    static CDIMService *imService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imService = [[CDIMService alloc] init];
    });
    return imService;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.im = [CDIM sharedInstance];
    }
    return self;
}

#pragma mark - user delegate

- (void)cacheUserByIds:(NSSet *)userIds block:(AVBooleanResultBlock)block {
    [CDCache cacheUsersWithIds:userIds callback:block];
}

- (id <CDUserModel> )getUserById:(NSString *)userId {
    CDUser *user = [[CDUser alloc] init];
    AVUser *avUser = [CDCache lookupUser:userId];
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
    CDChatVC *chatVC = [[CDChatVC alloc] initWithConv:conv];
    chatVC.hidesBottomBarWhenPushed = YES;
    [nav pushViewController:chatVC animated:YES];
}

- (void)goWithUserId:(NSString *)userId fromVC:(UIViewController *)vc {
    CDIM *im = [CDIM sharedInstance];
    [im fetchConvWithOtherId:userId callback: ^(AVIMConversation *conversation, NSError *error) {
        if (error) {
            DLog(@"%@", error);
        }
        else {
            [self goWithConv:conversation fromNav:vc.navigationController];
        }
    }];
}

@end

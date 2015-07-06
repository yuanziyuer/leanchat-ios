//
//  CDConvsVC.m
//  LeanChat
//
//  Created by lzw on 15/4/10.
//  Copyright (c) 2015年 LeanCloud. All rights reserved.
//

#import "CDConvsVC.h"
#import "CDUtils.h"
#import "CDIMService.h"

@interface CDConvsVC () <CDChatListVCDelegate>

@end

@implementation CDConvsVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"消息";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_chat_active"];
        self.chatListDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewController:(UIViewController *)viewController didSelectConv:(AVIMConversation *)conv {
    [[CDIMService service] goWithConv:conv fromNav:viewController.navigationController];
}

- (void)setBadgeWithTotalUnreadCount:(NSInteger)totalUnreadCount {
    if (totalUnreadCount > 0) {
        self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)totalUnreadCount];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:totalUnreadCount];
        AVInstallation *currentInstallation = [AVInstallation currentInstallation];
        [currentInstallation setBadge:totalUnreadCount];
        [currentInstallation saveEventually: ^(BOOL succeeded, NSError *error) {
            DLog(@"%@", error ? error : @"succeed");
        }];
    }
    else {
        self.tabBarItem.badgeValue = nil;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        AVInstallation *currentInstallation = [AVInstallation currentInstallation];
        [currentInstallation setBadge:0];
        [currentInstallation saveEventually: ^(BOOL succeeded, NSError *error) {
            DLog(@"%@", error ? error : @"succeed");
        }];
    }
}

@end

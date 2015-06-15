//
//  CDConvsVC.m
//  LeanChat
//
//  Created by lzw on 15/4/10.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDConvsVC.h"
#import "CDUtils.h"
#import "CDIMManager.h"

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
    [[CDIMManager manager] goWithConv:conv fromNav:viewController.navigationController];
}

- (void)setBadgeWithTotalUnreadCount:(NSInteger)totalUnreadCount {
    if (totalUnreadCount > 0) {
        self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)totalUnreadCount];
    }
    else {
        self.tabBarItem.badgeValue = nil;
    }
}

@end

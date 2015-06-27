//
//  CDConvsVC.m
//  LeanChat
//
//  Created by lzw on 15/4/10.
//  Copyright (c) 2015年 LeanCloud. All rights reserved.
//

#import "LCEChatListVC.h"
#import "LCEChatRoomVC.h"
#import "MainViewController.h"

@interface LCEChatListVC () <CDChatListVCDelegate>

@end

@implementation LCEChatListVC

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
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(rightBarButtonClicked:)];
    UIBarButtonItem *logoutItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStylePlain target:self action:@selector(logout:)];
    self.navigationItem.rightBarButtonItems = @[logoutItem, addItem];
}

- (void)logout:(id)sender {
    [[CDChatManager manager] closeWithCallback: ^(BOOL succeeded, NSError *error) {
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
        [self performSelector:@selector(exitApp:) withObject:nil afterDelay:0.5];
    }];
}

- (void)exitApp:(id)sender {
    exit(0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewController:(UIViewController *)viewController didSelectConv:(AVIMConversation *)conv {
    LCEChatRoomVC *chatRoomVC = [[LCEChatRoomVC alloc] initWithConv:conv];
    chatRoomVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:chatRoomVC animated:YES];
}

- (void)setBadgeWithTotalUnreadCount:(NSInteger)totalUnreadCount {
    if (totalUnreadCount > 0) {
        self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", totalUnreadCount];
    }
    else {
        self.tabBarItem.badgeValue = nil;
    }
}

- (void)rightBarButtonClicked:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MainViewController *mainVC = [storyBoard instantiateViewControllerWithIdentifier:@"main"];
    mainVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:mainVC animated:YES];
}

@end

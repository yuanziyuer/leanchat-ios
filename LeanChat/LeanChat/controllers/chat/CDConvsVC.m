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

@interface CDConvsVC ()<CDChatListVCDelegate>

@end

@implementation CDConvsVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"消息";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.chatListDelegate = self;
}

- (void)viewController:(UIViewController *)viewController didSelectConv:(AVIMConversation *)conv {
    [[CDIMService service] goWithConv:conv fromNav:viewController.navigationController];
}

- (void)setBadgeWithTotalUnreadCount:(NSInteger)totalUnreadCount {
    if (totalUnreadCount > 0) {
        self.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)totalUnreadCount];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:totalUnreadCount];
    }
    else {
        self.tabBarItem.badgeValue = nil;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
}

- (UIImage *)defaultAvatarImageView {
    UIImage *defaultAvatarImageView = [UIImage imageNamed:@"image_placeholder"];
    return defaultAvatarImageView;
}

- (CGFloat)avatarImageViewCornerRadius {
    return 3;
}

@end

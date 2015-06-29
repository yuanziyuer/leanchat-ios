//
//  CDProfileController.m
//  LeanChat
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 LeanCloud. All rights reserved.
//

#import "CDProfileVC.h"
#import "CDUserManager.h"
#import "CDAppDelegate.h"
#import "LZPushSettingViewController.h"
#import "CDWebViewVC.h"
#import <LeanChatLib/CDChatManager.h>
#import "MCPhotographyHelper.h"
#import "LCUserFeedbackAgent.h"
#import "LCUserFeedbackViewController.h"
#import "CDBaseNavC.h"

@interface CDProfileVC ()

@property (nonatomic, strong) MCPhotographyHelper *photographyHelper;

@end

@implementation CDProfileVC

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"我";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_me_active"];
        self.tableViewStyle = UITableViewStyleGrouped;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadDataSource];
}

- (MCPhotographyHelper *)photographyHelper {
    if (_photographyHelper == nil) {
        _photographyHelper = [[MCPhotographyHelper alloc] init];
    }
    return _photographyHelper;
}

- (void)loadDataSource {
    [self showProgress];
    [[CDUserManager manager] getBigAvatarimageOfUser:[AVUser currentUser] block:^(UIImage *image) {
        [[LCUserFeedbackAgent sharedInstance] countUnreadFeedbackThreadsWithContact:[AVUser currentUser].objectId block:^(NSInteger number, NSError *error) {
            [self hideProgress];
            self.dataSource = [NSMutableArray array];
            [self.dataSource addObject:@[@{ kMutipleSectionImageKey:image, kMutipleSectionTitleKey:[AVUser currentUser].username, kMutipleSectionSelectorKey:NSStringFromSelector(@selector(pickImage)) }]];
            [self.dataSource addObject:@[@{ kMutipleSectionTitleKey:@"消息通知", kMutipleSectionSelectorKey:NSStringFromSelector(@selector(goPushSetting)) }, @{ kMutipleSectionTitleKey:@"意见反馈", kMutipleSectionBadgeKey:@(number), kMutipleSectionSelectorKey:NSStringFromSelector(@selector(goFeedback)) }, @{ kMutipleSectionTitleKey:@"用户协议", kMutipleSectionSelectorKey:NSStringFromSelector(@selector(goTerms)) }]];
            [self.dataSource addObject:@[@{ kMutipleSectionTitleKey:@"退出登录", kMutipleSectionLogoutKey:@YES, kMutipleSectionSelectorKey:NSStringFromSelector(@selector(logout)) }]];
            [self.tableView reloadData];
        }];
    }];
}

#pragma mark - Actions

-(void)pickImage {
    [self.photographyHelper showOnPickerViewControllerOnViewController:self completion:^(UIImage *image) {
        if (image) {
            UIImage *rounded = [CDUtils roundImage:image toSize:CGSizeMake(100, 100) radius:10];
            [self showProgress];
            [[CDUserManager manager] saveAvatar : rounded callback : ^(BOOL succeeded, NSError *error) {
                [self hideProgress];
                if ([self filterError:error]) {
                    [self loadDataSource];
                }
            }];
        }
    }];
}

- (void)logout {
    [[CDChatManager manager] closeWithCallback: ^(BOOL succeeded, NSError *error) {
        DLog(@"%@", error);
        [AVUser logOut];
        CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate toLogin];
    }];
}

- (void)goTerms {
    CDWebViewVC *webViewVC = [[CDWebViewVC alloc] initWithURL:[NSURL URLWithString:@"https://leancloud.cn/terms.html"] title:@"用户协议"];
    webViewVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:webViewVC animated:YES];
}

- (void)goPushSetting {
    LZPushSettingViewController *controller = [[LZPushSettingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)goFeedback {
    LCUserFeedbackViewController *feedbackViewController = [[LCUserFeedbackViewController alloc] init];
    feedbackViewController.feedbackTitle = [AVUser currentUser].username;
    feedbackViewController.contact = [AVUser currentUser].objectId;
    CDBaseNavC *navigationController = [[CDBaseNavC alloc] initWithRootViewController:feedbackViewController];
    [self presentViewController:navigationController animated:YES completion: ^{
    }];
    [self performSelector:@selector(loadDataSource) withObject:nil afterDelay:1];
}

@end

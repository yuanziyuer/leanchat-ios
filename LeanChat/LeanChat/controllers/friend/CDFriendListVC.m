//
//  CDContactListController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/27/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDFriendListVC.h"
#import "CDCommon.h"
#import "CDAddFriendVC.h"
#import "CDBaseNavC.h"
#import "CDNewFriendVC.h"
#import "CDImageLabelTableCell.h"
#import "CDGroupedConvListVC.h"
#import <JSBadgeView/JSBadgeView.h>
#import "CDUtils.h"
#import "CDUserManager.h"
#import "CDIMService.h"

@interface CDFriendListVC () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *users;
@property (weak, nonatomic) IBOutlet UIView *myNewFriendView;
@property (weak, nonatomic) IBOutlet UIView *groupView;
@property (nonatomic, assign) NSInteger addRequestN;
@property (weak, nonatomic) IBOutlet UIImageView *myNewFriendIcon;
@property (nonatomic, strong) JSBadgeView *myNewFriendBadgeView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation CDFriendListVC

#pragma mark - Life Cycle
- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"联系人";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_contacts_active"];
        [self setNewAddRequestBadge];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                              target:self action:@selector(goAddFriend:)];
    [self setupNewFriendAndGroupView];
    [self setupTableView];
    [self refresh];
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView addSubview:self.refreshControl];
}

- (void)setupNewFriendAndGroupView {
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goNewFriend:)];
    [self.myNewFriendView addGestureRecognizer:singleTap];
    
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goGroup:)];
    [self.groupView addGestureRecognizer:singleTap];
    
    self.myNewFriendBadgeView.badgeText = nil;
}

- (UIRefreshControl *)refreshControl {
    if (_refreshControl == nil) {
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

- (JSBadgeView *)myNewFriendBadgeView {
    if (_myNewFriendBadgeView == nil) {
        _myNewFriendBadgeView = [[JSBadgeView alloc] initWithParentView:_myNewFriendIcon alignment:JSBadgeViewAlignmentTopRight];
        _myNewFriendBadgeView.badgeText = nil;
    }
    return _myNewFriendBadgeView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Action

- (void)goNewFriend:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(_addRequestN) forKey:@"addRequestN"];
    [userDefaults synchronize];
    self.myNewFriendBadgeView.badgeText = nil;
    CDNewFriendVC *controller = [[CDNewFriendVC alloc] init];
    controller.friendListVC = self;
    [[self navigationController] pushViewController:controller animated:YES];
    self.tabBarItem.badgeValue = nil;
}

- (void)goGroup:(id)sender {
    CDGroupedConvListVC *controller = [[CDGroupedConvListVC alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
}

- (void)goAddFriend:(UIBarButtonItem *)buttonItem {
    CDAddFriendVC *controller = [[CDAddFriendVC alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
}

#pragma mark - load data

- (void)refresh {
    [self refresh:nil];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [self showProgress];
    WEAKSELF
    [[CDUserManager manager] findFriendsWithBlock : ^(NSArray *objects, NSError *error) {
        if (refreshControl) {
            [CDUtils stopRefreshControl:refreshControl];
        }
        [weakSelf hideProgress];
        // why kAVErrorInternalServer ?
        if (error && (error.code == kAVErrorCacheMiss || error.code == kAVErrorInternalServer)) {
            // for the first start
            weakSelf.users = [NSMutableArray array];
            [weakSelf.tableView reloadData];
        }
        else {
            if ([self filterError:error]) {
                weakSelf.users = objects;
                [weakSelf.tableView reloadData];
            }
        }
    }];
    [self setNewAddRequestBadge];
}

- (void)setNewAddRequestBadge {
    WEAKSELF
    [[CDUserManager manager] countAddRequestsWithBlock : ^(NSInteger number, NSError *error) {
        [CDUtils logError:error callback: ^{
            _addRequestN = number;
            NSInteger oldN = [[NSUserDefaults standardUserDefaults] integerForKey:@"addRequestN"];
            if (_addRequestN > oldN) {
                NSString *badge = [NSString stringWithFormat:@"%ld", (long)(_addRequestN - oldN)];
                if (weakSelf.isViewLoaded) {
                    weakSelf.myNewFriendBadgeView.badgeText = badge;
                }
                weakSelf.tabBarItem.badgeValue = badge;
            }
            else {
                weakSelf.tabBarItem.badgeValue = nil;
                if (weakSelf.isViewLoaded) {
                    weakSelf.myNewFriendBadgeView.badgeText = nil;
                }
            }
        }];
    }];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ContactCell";
    static BOOL isRegisterNib = NO;
    if (isRegisterNib == NO) {
        [tableView registerNib:[UINib nibWithNibName:@"CDImageLabelTableCell" bundle:nil]
        forCellReuseIdentifier:cellIdentifier];
    }
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell *tableCell = (CDImageLabelTableCell *)cell;
    AVUser *user = [self.users objectAtIndex:indexPath.row];
    [[CDUserManager manager] displayAvatarOfUser:user avatarView:tableCell.myImageView];
    tableCell.myLabel.text = user.username;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AVUser *user = [self.users objectAtIndex:indexPath.row];
    [[CDIMService service] goWithUserId:user.objectId fromVC:self];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"解除好友关系吗" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        alertView.tag = indexPath.row;
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSInteger row = alertView.tag;
        AVUser *user = [_users objectAtIndex:row];
        [self showProgress];
        WEAKSELF
        [[CDUserManager manager] removeFriend : user callback : ^(BOOL succeeded, NSError *error) {
            [self hideProgress];
            if ([self filterError:error]) {
                [weakSelf refresh];
            }
        }];
    }
}

@end

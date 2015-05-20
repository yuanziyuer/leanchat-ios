//
//  CDUserInfoController.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDUserInfoVC.h"
#import <LeanChatLib/LeanChatLib.h>
#import "CDCache.h"
#import "CDUserService.h"
#import "CDUtils.h"
#import "CDIMService.h"

@interface CDUserInfoVC ()

@property (nonatomic, assign) BOOL isFriend;

@property (strong, nonatomic) AVUser *user;

@end

@implementation CDUserInfoVC

- (instancetype)initWithUser:(AVUser *)user {
    self = [super init];
    if (self) {
        _isFriend = NO;
        _user = user;
        self.tableViewStyle = UITableViewStyleGrouped;
    }
    return self;
}

#pragma lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"详情";
    [self refresh];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if (indexPath.section == 1) {
        if (self.isFriend) {
            cell.textLabel.text = @"开始聊天";
        }
        else {
            cell.textLabel.text = @"添加好友";
        }
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    else {
        cell.textLabel.text = self.user.username;
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        [CDUserService displayBigAvatarOfUser:self.user avatarView:cell.imageView];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 88;
    }
    else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        if (self.isFriend) {
            [[CDIMService shareInstance] goWithUserId:self.user.objectId fromVC:self];
        }
        else {
            [CDUtils showNetworkIndicator];
            [CDUserService tryCreateAddRequestWithToUser:_user callback: ^(BOOL succeeded, NSError *error) {
                [CDUtils hideNetworkIndicator];
                if ([CDUtils filterError:error]) {
                    [CDUtils alert:@"请求成功"];
                }
            }];
        }
    }
}

- (void)refresh {
    WEAKSELF
    [CDUserService isMyFriend : _user block : ^(BOOL isFriend, NSError *error) {
        if ([CDUtils filterError:error]) {
            weakSelf.isFriend = isFriend;
            [weakSelf.tableView reloadData];
        }
    }];
}

@end

//
//  CDUserInfoController.m
//  LeanChat
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 LeanCloud. All rights reserved.
//

#import "CDUserInfoVC.h"
#import "CDCacheManager.h"
#import "CDUserManager.h"
#import "CDUtils.h"
#import "CDIMService.h"

@interface CDUserInfoVC ()

@property (strong, nonatomic) AVUser *user;

@end

@implementation CDUserInfoVC

- (instancetype)initWithUser:(AVUser *)user {
    self = [super init];
    if (self) {
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

- (void)goChat {
    [[CDIMService service] goWithUserId:self.user.objectId fromVC:self];
}

- (void)tryCreateAddRequest {
    [self showProgress];
    [[CDUserManager manager] tryCreateAddRequestWithToUser:_user callback: ^(BOOL succeeded, NSError *error) {
        [self hideProgress];
        [self alertError:error];
    }];
}

- (void)refresh {
    [self showProgress];
    [[CDUserManager manager] isMyFriend : _user block : ^(BOOL isFriend, NSError *error) {
        [self hideProgress];
        if ([self filterError:error]) {
            [[CDUserManager manager] getBigAvatarimageOfUser:_user block:^(UIImage *image) {
                self.dataSource =[NSMutableArray array];
                [self.dataSource addObject:@[@{kMutipleSectionImageKey:image, kMutipleSectionTitleKey:self.user.username}]];
                NSString *title;
                NSString *selector;
                if (isFriend) {
                    title = @"开始聊天";
                    selector = NSStringFromSelector(@selector(goChat));
                } else {
                    title = @"添加好友";
                    selector = NSStringFromSelector(@selector(tryCreateAddRequest));
                }
                [self.dataSource addObject:@[@{ kMutipleSectionTitleKey: title , kMutipleSectionSelectorKey:selector }]];
                [self.tableView reloadData];
            }];
        }
    }];
}

@end

//
//  CDGroupAddMemberController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/7.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDAddMemberVC.h"
#import "CDImageLabelTableCell.h"
#import "CDUserManager.h"
#import "CDCacheManager.h"
#import "CDUtils.h"
#import "CDIMManager.h"
#import <LeanChatLib/CDIM.h>


@interface CDAddMemberVC ()

@property NSMutableArray *selected;

@property NSMutableArray *potentialIds;

@end

@implementation CDAddMemberVC

static NSString *reuseIdentifier = @"Cell";

- (instancetype)init {
    self = [super init];
    if (self) {
        _selected = [NSMutableArray array];
        _potentialIds = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([CDImageLabelTableCell class]) bundle:nil] forCellReuseIdentifier:reuseIdentifier];
    
    self.title = @"邀请好友";
    [self initBarButton];
    [self refresh];
}

- (void)initBarButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(invite)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(backPressed:)];
}

- (void)refresh {
    WEAKSELF
    [[CDUserManager manager] findFriendsWithBlock: ^(NSArray *friends, NSError *error) {
        if ([self filterError:error]) {
            [_potentialIds removeAllObjects];
            for (AVUser *user in friends) {
                if ([[[CDCacheManager manager] getCurConv].members containsObject:user.objectId] == NO) {
                    [_potentialIds addObject:user.objectId];
                }
            }
            NSInteger count = _potentialIds.count;
            for (int i = 0; i < count; i++) {
                [_selected addObject:[NSNumber numberWithBool:NO]];
            }
            [weakSelf.tableView reloadData];
        }
    }];
}

- (void)backPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)invite {
    NSMutableArray *inviteIds = [[NSMutableArray alloc] init];
    for (int i = 0; i < _selected.count; i++) {
        if ([_selected[i] boolValue]) {
            [inviteIds addObject:[_potentialIds objectAtIndex:i]];
        }
    }
    if (inviteIds.count == 0) {
        [self backPressed:nil];
        return;
    }
    AVIMConversation *conv = [[CDCacheManager manager] getCurConv];
    if ([[CDCacheManager manager] getCurConv].type == CDConvTypeSingle) {
        NSMutableArray *members = [conv.members mutableCopy];
        [members addObjectsFromArray:inviteIds];
        [self showProgress];
        [[CDIM sharedInstance] createConvWithMembers:members type:CDConvTypeGroup callback: ^(AVIMConversation *conversation, NSError *error) {
            [self hideProgress];
            if ([self filterError:error]) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion: ^{
                    [[CDIMManager manager] goWithConv:conversation fromNav:_groupDetailVC.navigationController];
                }];
            }
        }];
    }
    else {
        [self showProgress];
        [conv addMembersWithClientIds:inviteIds callback: ^(BOOL succeeded, NSError *error) {
            if (error) {
                [self hideProgress];
                [self alertError:error];
            }
            else {
                [[CDCacheManager manager] refreshCurConv: ^(BOOL succeeded, NSError *error) {
                    [self hideProgress];
                    if ([self filterError:error]) {
                        [self backPressed:nil];
                    }
                }];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _potentialIds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[CDImageLabelTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    NSString *userId = [_potentialIds objectAtIndex:indexPath.row];
    AVUser *user = [[CDCacheManager manager] lookupUser:userId];
    [[CDUserManager manager] displayAvatarOfUser:user avatarView:cell.myImageView];
    cell.myLabel.text = user.username;
    if ([_selected[indexPath.row] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger pos = indexPath.row;
    _selected[pos] = [NSNumber numberWithBool:![_selected[pos] boolValue]];
    [self.tableView reloadData];
}

@end

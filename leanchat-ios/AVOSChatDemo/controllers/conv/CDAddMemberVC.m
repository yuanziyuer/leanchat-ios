//
//  CDGroupAddMemberController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/7.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDAddMemberVC.h"
#import "CDImageLabelTableCell.h"
#import <LeanChatLib/LeanChatLib.h>
#import "CDUserService.h"
#import "CDCache.h"
#import "CDUtils.h"
#import "CDIMService.h"

@interface CDAddMemberVC ()

@property NSMutableArray *selected;

@property NSMutableArray *potentialIds;

@property CDNotify *notify;

@property CDIM *im;

@end

@implementation CDAddMemberVC

static NSString *reuseIdentifier = @"Cell";

- (instancetype)init {
    self = [super init];
    if (self) {
        _selected = [NSMutableArray array];
        _potentialIds = [NSMutableArray array];
        _im = [CDIM sharedInstance];
        _notify = [CDNotify sharedInstance];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *nibName = NSStringFromClass([CDImageLabelTableCell class]);
    UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
    
    self.title = @"邀请好友";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(invite)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(backPressed:)];
    [self refresh];
}

- (void)refresh {
    WEAKSELF
    [CDUserService findFriendsWithBlock : ^(NSArray *friends, NSError *error) {
        if ([CDUtils filterError:error]) {
            [_potentialIds removeAllObjects];
            for (AVUser *user in friends) {
                if ([[CDCache getCurConv].members containsObject:user.objectId] == NO) {
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
    AVIMConversation *conv = [CDCache getCurConv];
    if ([CDCache getCurConv].type == CDConvTypeSingle) {
        NSMutableArray *members = [conv.members mutableCopy];
        [members addObjectsFromArray:inviteIds];
        [CDUtils showNetworkIndicator];
        [_im createConvWithMembers:members type:CDConvTypeGroup callback: ^(AVIMConversation *conversation, NSError *error) {
            [CDUtils hideNetworkIndicator];
            if ([CDUtils filterError:error]) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion: ^{
                    UINavigationController *nav = _groupDetailVC.navigationController;
                    [nav popToRootViewControllerAnimated:YES];
                    [[CDIMService shareInstance] goWithConv:conversation fromNav:nav];
                }];
            }
        }];
    }
    else {
        [CDUtils showNetworkIndicator];
        [conv addMembersWithClientIds:inviteIds callback: ^(BOOL succeeded, NSError *error) {
            if (error) {
                [CDUtils hideNetworkIndicator];
                [CDUtils alertError:error];
            }
            else {
                [CDCache refreshCurConv: ^(BOOL succeeded, NSError *error) {
                    [CDUtils hideNetworkIndicator];
                    if ([CDUtils filterError:error]) {
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
    AVUser *user = [CDCache lookupUser:userId];
    [CDUserService displayAvatarOfUser:user avatarView:cell.myImageView];
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

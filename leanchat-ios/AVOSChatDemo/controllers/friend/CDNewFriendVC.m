//
//  CDNewFriendTableViewController.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDNewFriendVC.h"
#import "CDUserInfoVC.h"
#import "CDUtils.h"
#import "CDLabelButtonTableCell.h"
#import "CDAddRequest.h"
#import "CDUserService.h"

@interface CDNewFriendVC ()

@property (nonatomic,strong) NSArray *addRequests;

@end

@implementation CDNewFriendVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"新的朋友";
    
    UIRefreshControl* refreshControl=[[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl=refreshControl;
    
    [self refresh:nil];
}

-(void)refresh:(UIRefreshControl*)refreshControl{
    [CDUtils showNetworkIndicator];
    WEAKSELF
    [CDUserService findAddRequestsWithBlock:^(NSArray *objects, NSError *error) {
        [CDUtils hideNetworkIndicator];
        if(refreshControl){
            [refreshControl endRefreshing];
        }
        if(error.code==kAVErrorObjectNotFound || error.code==kAVErrorCacheMiss){
        }else{
            [CDUtils filterError:error callback:^{
                _addRequests=objects;
                [weakSelf.tableView reloadData];
            }];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _addRequests.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static BOOL isRegNib=NO;
    if(!isRegNib){
        [tableView registerNib:[UINib nibWithNibName:@"CDLabelButtonTableCell" bundle:nil]forCellReuseIdentifier:@"cell"];
    }
    CDLabelButtonTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" ];
    CDAddRequest* addRequest=[_addRequests objectAtIndex:indexPath.row];
    cell.nameLabel.text=addRequest.fromUser.username;
    [CDUserService displayAvatarOfUser:addRequest.fromUser avatarView:cell.leftImageView];
    if(addRequest.status==CDAddRequestStatusWait){
        cell.actionBtn.enabled=true;
        cell.actionBtn.tag=indexPath.row;
        [cell.actionBtn setTitle:@"同意" forState:UIControlStateNormal];
        [cell.actionBtn addTarget:self action:@selector(actionBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }else{
        cell.actionBtn.enabled=false;
        [cell.actionBtn setTitle:@"已同意" forState:UIControlStateNormal];
        cell.selectionStyle=UITableViewCellSelectionStyleDefault;
    }
    return cell;
}

-(void)actionBtnClicked:(id)sender{
    UIButton *btn=(UIButton*)sender;
    CDAddRequest* addRequest=[_addRequests objectAtIndex:btn.tag];
    [CDUtils showNetworkIndicator];
    WEAKSELF
    [CDUserService agreeAddRequest:addRequest callback:^(BOOL succeeded, NSError *error) {
        [CDUtils hideNetworkIndicator];
        if([CDUtils filterError:error]){
            [CDUtils alert:@"添加成功"];
            [weakSelf refresh:nil];
            [_friendListVC refresh];
        }
    }];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CDAddRequest* addRequest=self.addRequests[indexPath.row];
    CDUserInfoVC *userInfoVC=[[CDUserInfoVC alloc] initWithUser:addRequest.fromUser];
    [self.navigationController pushViewController:userInfoVC animated:YES];
}

@end

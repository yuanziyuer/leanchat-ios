//
//  CDNewFriendTableViewController.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDNewFriendVC.h"
#import "CDViews.h"
#import "CDService.h"
#import "CDUtils.h"

@interface CDNewFriendVC (){
    NSArray *addRequests;
}
@end

@implementation CDNewFriendVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIRefreshControl* refreshControl=[[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl=refreshControl;
    self.title=@"新的朋友";
    [self refresh:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)refresh:(id)sender{
    BOOL onlyNetwork;
    if(sender==nil){
        onlyNetwork=NO;
    }else{
        onlyNetwork=YES;
    }
    [CDUtils showNetworkIndicator];
    [CDUserService findAddRequestsOnlyByNetwork:onlyNetwork withCallback:^(NSArray *objects, NSError *error) {
        [CDUtils hideNetworkIndicator];
        [self.refreshControl endRefreshing];
        if(error.code==kAVErrorObjectNotFound){
        }else{
            [CDUtils filterError:error callback:^{
                addRequests=objects;
                [self.tableView reloadData];
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
    return addRequests.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static BOOL isRegNib=NO;
    if(!isRegNib){
        [tableView registerNib:[UINib nibWithNibName:@"CDLabelButtonTableCell" bundle:nil]forCellReuseIdentifier:@"cell"];
    }
    CDLabelButtonTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" ];
    CDAddRequest* addRequest=[addRequests objectAtIndex:indexPath.row];
    cell.nameLabel.text=addRequest.fromUser.username;
    [CDUserService displayAvatarOfUser:addRequest.fromUser avatarView:cell.leftImageView];
    if(addRequest.status==CDAddRequestStatusWait){
        cell.actionBtn.enabled=true;
        cell.actionBtn.tag=indexPath.row;
        [cell.actionBtn setTitle:@"同意" forState:UIControlStateNormal];
        [cell.actionBtn addTarget:self action:@selector(actionBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        cell.actionBtn.enabled=false;
        [cell.actionBtn setTitle:@"已同意" forState:UIControlStateNormal];
    }
    return cell;
}

-(void)actionBtnClicked:(id)sender{
    UIButton *btn=(UIButton*)sender;
    CDAddRequest* addRequest=[addRequests objectAtIndex:btn.tag];
    
    [CDUtils showNetworkIndicator];
    [CDUserService agreeAddRequest:addRequest callback:^(BOOL succeeded, NSError *error) {
        [CDUtils hideNetworkIndicator];
        if([CDUtils filterError:error]){
            [CDUtils alert:@"添加成功"];
            [self refresh:sender];
            [_friendListVC refresh];
        }
    }];
}

@end

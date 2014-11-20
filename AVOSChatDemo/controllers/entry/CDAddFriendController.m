//
//  CDAddFriendController.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDAddFriendController.h"
#import "UserService.h"
#import "CDBaseNavigationController.h"
#import "CDUserInfoController.h"
#import "CDImageLabelTableCell.h"

@interface CDAddFriendController (){
    NSArray *users;
}
@end

static NSString* cellIndentifier=@"cellIndentifier";

@implementation CDAddFriendController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"查找好友";
    [_searchBar setDelegate:self];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    UINib* nib=[UINib nibWithNibName:NSStringFromClass([CDImageLabelTableCell class]) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:cellIndentifier];
    [self searchUser:@""];
    // Do any additional setup after loading the view from its nib.
}

-(void)searchUser:(NSString *)name{
    [UserService findUsersByPartname:name withBlock:^(NSArray *objects, NSError *error) {
        if(objects){
            users=objects;
            [_tableView reloadData];
        }
    }];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [users count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CDImageLabelTableCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIndentifier forIndexPath:indexPath];
    if(!cell){
        cell=[[CDImageLabelTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
    }
    AVUser *user=users[indexPath.row];
    cell.myLabel.text=user.username;
    [UserService displayAvatarOfUser:user avatarView:cell.myImageView];
    return cell;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //NSLog(@"select");
    AVUser *user=users[indexPath.row];
    CDUserInfoController *controller=[[CDUserInfoController alloc] init];
    controller.user=user;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
    NSString* content=[searchBar text];
    [self searchUser:content];
}


@end

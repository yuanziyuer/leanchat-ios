//
//  CDContactListController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/27/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDContactListController.h"
#import "CDCommon.h"
#import "UserService.h"
#import "CDAddFriendController.h"
#import "CDBaseNavigationController.h"
#import "CDNewFriendTableViewController.h"
#import "CDUserInfoController.h"
#import "CDSessionManager.h"
#import "CDImageLabelTableCell.h"
#import "CDGroupTableViewController.h"
#import "Utils.h"

enum : NSUInteger {
    kTagNameLabel = 10000,
};
@interface CDContactListController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *users;
@property (weak, nonatomic) IBOutlet UIView *myNewFriendView;
@property (weak, nonatomic) IBOutlet UIView *groupView;

@end

@implementation CDContactListController
- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"联系人";
        self.tabBarItem.image = [UIImage imageNamed:@"contact"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]
                                            initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                            target:self action:@selector(goAddFriend:)];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    
    UITapGestureRecognizer *singleTap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goNewFriend:)];
    [self.myNewFriendView addGestureRecognizer:singleTap];
    
    singleTap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goGroup:)];
    [self.groupView addGestureRecognizer:singleTap];
    //[self.myNewFriendView addGestureRecognizer:singleTap];
}

-(void)goNewFriend:(id)sender{
    CDNewFriendTableViewController *controller=[[CDNewFriendTableViewController alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
}

-(void)goGroup:(id)sender{
    CDGroupTableViewController *controller=[[CDGroupTableViewController alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
}

-(void)goAddFriend:(UIBarButtonItem*)buttonItem{
    CDAddFriendController *controller = [[CDAddFriendController alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startFetchUserList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startFetchUserList {
    [Utils showNetworkIndicator];
    [UserService findFriendsWithCallback:^(NSArray *objects, NSError *error) {
        [Utils hideNetworkIndicator];
        if (objects) {
            self.users = [objects mutableCopy];
            CDSessionManager* sessionMan=[CDSessionManager sharedInstance];
            [sessionMan registerUsers:self.users];
            [sessionMan setFriends:self.users];
            [self.tableView reloadData];
        } else {
            NSLog(@"error:%@", error);
        }
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ContactCell";
    static BOOL isRegisterNib=NO;
    if(isRegisterNib==NO){
        [tableView registerNib:[UINib nibWithNibName:@"CDImageLabelTableCell" bundle:nil]
          forCellReuseIdentifier:cellIdentifier];
    }
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell* tableCell=(CDImageLabelTableCell*)cell;
    AVUser *user = [self.users objectAtIndex:indexPath.row];
    [UserService displayAvatarOfUser:user avatarView:tableCell.myImageView];
    tableCell.myLabel.text = user.username;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AVUser *user = [self.users objectAtIndex:indexPath.row];
    CDUserInfoController *controller=[[CDUserInfoController alloc] initWithUser:user];
    [self.navigationController pushViewController:controller animated:YES];
}


@end

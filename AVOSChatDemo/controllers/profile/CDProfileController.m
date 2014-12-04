//
//  CDProfileController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDProfileController.h"
#import "CDCommon.h"
#import "CDLoginController.h"
#import "CDAppDelegate.h"
#import "CDSessionManager.h"
#import "ResizableButton.h"

@interface CDProfileController ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITableViewCell *avatarCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *logoutCell;

@end

@implementation CDProfileController

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"我";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_me_active"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AVUser *user = [AVUser currentUser];
    NSString *username = [user username];
    if ([user mobilePhoneVerified]) {
        username = [NSString stringWithFormat:@"%@(%@)", username, [user mobilePhoneNumber]];
    }
    self.nameLabel.text = username;
    [CDUserService displayAvatarOfUser:user avatarView:self.avatarView];
    //_tableView.autoresizingMask=UIViewAutoresizingFlexibleHeight;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

-(void)logout {
    [[CDSessionManager sharedInstance] clearData];
    [AVUser logOut];
    CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate toLogin];
}

#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    int section=indexPath.section;
    switch (section) {
        case 0:
            return _avatarCell;
        default:
            _logoutCell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            return _logoutCell;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    int section=indexPath.section;
    if(section==1){
        [self logout];
    }
}

@end

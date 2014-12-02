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
@property (weak, nonatomic) IBOutlet ResizableButton *logoutBtn;

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
    [self.logoutBtn addTarget:self action:@selector(logout:) forControlEvents:UIControlEventTouchUpInside];
    [CDUserService displayAvatarOfUser:user avatarView:self.avatarView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

-(void)logout:(id)sender {
    [[CDSessionManager sharedInstance] clearData];
    [AVUser logOut];
    CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate toLogin];
}

@end

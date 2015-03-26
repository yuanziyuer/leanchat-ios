//
//  CDProfileController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDProfileVC.h"
#import "CDService.h"
#import "CDCommon.h"
#import "CDLoginVC.h"
#import "CDAppDelegate.h"
#import "CDResizableButton.h"
#import "JSBadgeView.h"
#import "CDBadgeLabel.h"
#import "CDPushSettingVC.h"

@interface CDProfileVC ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITableViewCell *avatarCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *logoutCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *upgradeCell;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *upgradeAction;
@property (strong, nonatomic) IBOutlet UITableViewCell *pushSettingCell;

@property (strong,nonatomic) JSBadgeView *badgeView;

@property (nonatomic,assign) BOOL haveNewVersion;

@end

@implementation CDProfileVC

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"我";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_me_active"];
        _haveNewVersion=NO;
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
    NSString* str=@"当前:v";
    [_versionLabel setText:[str stringByAppendingString:[CDUpgradeService currentVersion]]];
    
    _badgeView = [[JSBadgeView alloc] initWithParentView:_upgradeAction alignment:JSBadgeViewAlignmentTopRight];
    _badgeView.badgeText=@"New";
    _badgeView.hidden=YES;
    
    [CDUtils showNetworkIndicator];
    [CDUpgradeService findNewVersionWithBlock:^(BOOL succeeded, NSError *error) {
        [CDUtils hideNetworkIndicator];
        [CDUtils filterError:error callback:^{
            if(succeeded){
                _haveNewVersion=YES;
            }else{
                _haveNewVersion=NO;
            }
            _badgeView.hidden=!_haveNewVersion;
        }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

-(void)logout {
    [[CDIM sharedInstance] close];
    [AVUser logOut];
    CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate toLogin];
}

#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    int section=indexPath.section;
    UITableViewCell* cell;
    switch (section) {
        case 0:
            cell=_avatarCell;
            break;
        case 1:
            cell=_pushSettingCell;
            break;
        case 2:
            cell=_upgradeCell;
            break;
        case 3:
            cell=_logoutCell;
            break;
    }
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

-(void)goPushSetting{
    CDPushSettingVC* controller=[[CDPushSettingVC alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    int section=indexPath.section;
    switch (section) {
        case 0:
            [CDUtils pickImageFromPhotoLibraryAtController:self];
            break;
        case 1:
            [self goPushSetting];
            break;
        case 2:
            if(_haveNewVersion){
                NSURL *url = [NSURL URLWithString:@"http://fir.im/Lean"];
                [[UIApplication sharedApplication] openURL:url];
            }else{
                [CDUtils alert:@"已经是最新版本"];
            }
            break;
        case 3:
            [self logout];
            break;
    }
}

#pragma mark - image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:YES completion:^{
        UIActivityIndicatorView* indicator=[CDUtils showIndicatorAtView:self.view];
        UIImage* image=info[UIImagePickerControllerEditedImage];
        UIImage* rounded=[CDUtils roundImage:image toSize:CGSizeMake(200, 200) radius:20];
        [CDUserService saveAvatar:rounded callback:^(BOOL succeeded, NSError *error) {
            [indicator stopAnimating];
            [CDUtils filterError:error callback:^{
                self.avatarView.image=rounded;
            }];
        }];
    }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

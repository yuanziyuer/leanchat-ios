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
#import <LeanChatLib/JSBadgeView.h>
#import "CDBadgeLabel.h"
#import "CDPushSettingVC.h"
#import "CDWebViewVC.h"
#import <LeanChatLib/LeanChatLib.h>

@interface CDProfileVC ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITableViewCell *avatarCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *logoutCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *pushSettingCell;

@property (strong, nonatomic) IBOutlet UITableViewCell *termsCell;

@end

@implementation CDProfileVC

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"我";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_me_active"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AVUser* user=[AVUser currentUser];
    self.nameLabel.text = user.username;
    [CDUserService displayAvatarOfUser:user avatarView:self.avatarView];
}

#pragma mark - Actions

-(void)logout {
    [[CDIM sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
        DLog(@"%@",error);
        [AVUser logOut];
        CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate toLogin];
    }];
}

-(void)goTerms{
    CDWebViewVC *webViewVC=[[CDWebViewVC alloc] initWithURL:[NSURL URLWithString:@"https://leancloud.cn/terms.html"] title:@"用户协议"];
    webViewVC.hidesBottomBarWhenPushed=YES;
    [self.navigationController pushViewController:webViewVC animated:YES];
}

-(void)goPushSetting{
    CDPushSettingVC* controller=[[CDPushSettingVC alloc] init];
    controller.hidesBottomBarWhenPushed=YES;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger section=indexPath.section;
    UITableViewCell* cell;
    switch (section) {
        case 0:
            cell=_avatarCell;
            break;
        case 1:
            cell=_pushSettingCell;
            break;
        case 2:
            cell=_termsCell;
            break;
        case 3:
            cell=_logoutCell;
            break;
    }
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger section=indexPath.section;
    switch (section) {
        case 0:
            [CDUtils pickImageFromPhotoLibraryAtController:self];
            break;
        case 1:
            [self goPushSetting];
            break;
        case 2:
            [self goTerms];
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

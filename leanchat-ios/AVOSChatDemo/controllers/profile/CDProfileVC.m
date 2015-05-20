//
//  CDProfileController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDProfileVC.h"
#import "CDUserService.h"
#import "CDAppDelegate.h"
#import "CDPushSettingVC.h"
#import "CDWebViewVC.h"

@interface CDProfileVC ()

@end

@implementation CDProfileVC

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"我";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_me_active"];
        self.tableViewStyle = UITableViewStyleGrouped;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = [@[[AVUser currentUser].username, @"消息通知", @"用户协议", @"退出登录"] mutableCopy];
}

#pragma mark - Actions

- (void)logout {
    [[CDIM sharedInstance] closeWithCallback: ^(BOOL succeeded, NSError *error) {
        DLog(@"%@", error);
        [AVUser logOut];
        CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate toLogin];
    }];
}

- (void)goTerms {
    CDWebViewVC *webViewVC = [[CDWebViewVC alloc] initWithURL:[NSURL URLWithString:@"https://leancloud.cn/terms.html"] title:@"用户协议"];
    webViewVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:webViewVC animated:YES];
}

- (void)goPushSetting {
    CDPushSettingVC *controller = [[CDPushSettingVC alloc] init];
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = self.dataSource[indexPath.section];
    if (indexPath.section == 0) {
        [CDUserService displayBigAvatarOfUser:[AVUser currentUser] avatarView:cell.imageView];
    }
    else {
        cell.imageView.image = nil;
    }
    if (indexPath.section == self.dataSource.count - 1) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 88;
    }
    else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger section = indexPath.section;
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion: ^{
        UIActivityIndicatorView *indicator = [CDUtils showIndicatorAtView:self.view];
        UIImage *image = info[UIImagePickerControllerEditedImage];
        UIImage *rounded = [CDUtils roundImage:image toSize:CGSizeMake(100, 100) radius:10];
        WEAKSELF
        [CDUserService saveAvatar : rounded callback : ^(BOOL succeeded, NSError *error) {
            [indicator stopAnimating];
            [CDUtils filterError:error callback: ^{
                [weakSelf.tableView reloadData];
            }];
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

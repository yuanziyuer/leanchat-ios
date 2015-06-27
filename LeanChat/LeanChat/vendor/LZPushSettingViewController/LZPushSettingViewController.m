//
//  CDPushSettingController.m
//  LeanChat
//
//  Created by lzw on 15/1/15.
//  Copyright (c) 2015年 LeanCloud. All rights reserved.
//

#import "LZPushSettingViewController.h"

static CGFloat kHorizontalSpacing = 40;
static CGFloat kFooterHeight = 40;

@interface LZPushSettingViewController ()

@property (strong, nonatomic) UITableViewCell *receiveMessageCell;

@property (nonatomic, strong) UILabel *tipsLabel;

@end

@implementation LZPushSettingViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"消息通知"];
}

- (BOOL)isNotificationEnabled {
    UIApplication *application = [UIApplication sharedApplication];
    BOOL enabled;
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        // ios8
        enabled = [application isRegisteredForRemoteNotifications];
    }
    else {
        UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
        enabled = types & UIRemoteNotificationTypeAlert;
    }
    return enabled;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return kFooterHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIndentifier = @"cellIndentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIndentifier];
    }
    cell.textLabel.text = @"接收新消息通知";
    if ([self isNotificationEnabled]) {
        cell.detailTextLabel.text = @"已开启";
    }
    else {
        cell.detailTextLabel.text = @"已关闭";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return self.tipsLabel;
    }
    return nil;
}

- (UILabel *)tipsLabel {
    if (_tipsLabel == nil) {
        _tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(kHorizontalSpacing, 0, CGRectGetWidth([UIScreen mainScreen].bounds) - 2 * kHorizontalSpacing, kFooterHeight)];
        [_tipsLabel setFont:[UIFont systemFontOfSize:10]];
        [_tipsLabel setTextColor:[UIColor grayColor]];
        _tipsLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.numberOfLines = 0;
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        _tipsLabel.text = [NSString stringWithFormat:@"如果你要关闭或开启%@的新消息通知，请在 iPhone 的\"设置\"-\"通知\"功能中，找到应用程序%@更改。", appName, appName];
    }
    return _tipsLabel;
}



@end

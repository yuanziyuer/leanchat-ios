//
//  CDPushSettingController.m
//  LeanChat
//
//  Created by lzw on 15/1/15.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDPushSettingVC.h"

@interface CDPushSettingVC ()

@property (strong, nonatomic) UITableViewCell *receiveMessageCell;

@property (nonatomic, assign) BOOL receiveOn;

@end

static NSString *cellIndentifier = @"cellIndentifier";

@implementation CDPushSettingVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tableViewStyle = UITableViewStyleGrouped;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"消息通知"];
    
    _receiveOn = [self isNotificationEnabled];
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
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
        CGFloat pad = 30;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(pad, 0, tableView.frame.size.width - 2 * pad, 40)];
        label.bounds = CGRectInset(label.frame, 20, 20);
        [label setFont:[UIFont systemFontOfSize:10]];
        [label setTextColor:[UIColor grayColor]];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.text = @"如果你要关闭或开启 LeanChat 的新消息通知，请在 iPhone 的\"设置\"-\"通知\"功能中，找到应用程序 LeanChat 更改。";
        return label;
    }
    return nil;
}

@end

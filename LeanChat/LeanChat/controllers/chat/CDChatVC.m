//
//  CDChatVC.m
//  LeanChat
//
//  Created by lzw on 15/4/10.
//  Copyright (c) 2015年 LeanCloud. All rights reserved.
//

#import "CDChatVC.h"
#import "CDConvDetailVC.h"
#import "CDUserInfoVC.h"

#import "CDCacheManager.h"
#import "AVIMUserInfoMessage.h"

@interface CDChatVC ()

@end

@implementation CDChatVC

- (instancetype)initWithConv:(AVIMConversation *)conv {
    self = [super initWithConv:conv];
    [[CDCacheManager manager] setCurConv:conv];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"chat_menu_people"] style:UIBarButtonItemStyleDone target:self action:@selector(goChatGroupDetail:)];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)testSendCustomeMessage {
    AVIMUserInfoMessage *userInfoMessage = [AVIMUserInfoMessage messageWithAttributes:@{ @"nickname":@"lzw" }];
    [self.conv sendMessage:userInfoMessage callback: ^(BOOL succeeded, NSError *error) {
        DLog(@"%@", error);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)goChatGroupDetail:(id)sender {
    [self.navigationController pushViewController:[[CDConvDetailVC alloc] init] animated:YES];
}

- (void)didSelectedAvatorOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    AVIMTypedMessage *msg = self.msgs[indexPath.row];
    if ([msg.clientId isEqualToString:[CDChatManager manager].selfId] == NO) {
        CDUserInfoVC *userInfoVC = [[CDUserInfoVC alloc] initWithUser:[[CDCacheManager manager] lookupUser:msg.clientId]];
        [self.navigationController pushViewController:userInfoVC animated:YES];
    }
}

@end

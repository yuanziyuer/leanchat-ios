//
//  CDChatVC.m
//  LeanChat
//
//  Created by lzw on 15/4/10.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDChatVC.h"
#import "CDCache.h"
#import "CDConvDetailVC.h"

@interface CDChatVC ()

@end

@implementation CDChatVC

-(instancetype)initWithConv:(AVIMConversation *)conv{
    self=[super initWithConv:conv];
    [CDCache setCurConv:conv];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage* _peopleImage=[UIImage imageNamed:@"chat_menu_people"];
    UIBarButtonItem* item=[[UIBarButtonItem alloc] initWithImage:_peopleImage style:UIBarButtonItemStyleDone target:self action:@selector(goChatGroupDetail:)];
    self.navigationItem.rightBarButtonItem=item;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)goChatGroupDetail:(id)sender {
    CDConvDetailVC* controller=[[CDConvDetailVC alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end

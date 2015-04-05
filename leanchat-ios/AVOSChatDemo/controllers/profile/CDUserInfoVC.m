//
//  CDUserInfoController.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDUserInfoVC.h"
#import <LeanChatLib/LeanChatLib.h>
#import "CDCache.h"
#import "CDService.h"

@interface CDUserInfoVC (){
    BOOL isFriend;
    CDIM* imClient;
}

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionBtn;

@end

@implementation CDUserInfoVC

-(instancetype)initWithUser:(AVUser*)user{
    if(self==[super init]){
        _user=user;
    };
    return self;
}

#pragma lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"详情";
    _nameLabel.text=_user.username;
    isFriend=[[CDCache getFriends] containsObject:_user];
    [_actionBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    if(isFriend){
        [_actionBtn setTitle:@"开始聊天" forState:UIControlStateNormal];
    }else{
        [_actionBtn setTitle:@"添加好友" forState:UIControlStateNormal];
    }
    imClient=[CDIM sharedInstance];

    [CDUserService displayAvatarOfUser:_user avatarView:self.avatarView];
}

#pragma actions

-(void)btnClicked:(UIButton*)button{
    if(isFriend){
        [[CDIMService shareInstance] goWithUserId:self.user.objectId fromVC:self];
    }else{
        [CDUtils showNetworkIndicator];
        [CDUserService tryCreateAddRequestWithToUser:_user callback:^(BOOL succeeded, NSError *error) {
            [CDUtils hideNetworkIndicator];
            if([CDUtils filterError:error]){
                [CDUtils alert:@"请求成功"];
            }
        }];
    }
}

@end

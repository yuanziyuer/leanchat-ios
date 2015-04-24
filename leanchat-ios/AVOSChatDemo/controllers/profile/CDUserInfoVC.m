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

@interface CDUserInfoVC ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionBtn;


@property (strong,nonatomic) AVUser *user;

@end

@implementation CDUserInfoVC

-(instancetype)initWithUser:(AVUser*)user{
    self=[super init];
    if(self){
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
    [CDUserService displayAvatarOfUser:_user avatarView:self.avatarView];
    [self refresh];
}

-(void)refresh{
    _actionBtn.hidden=YES;
    [CDUserService isMyFriend:_user block:^(BOOL isFriend, NSError *error) {
        if([CDUtils filterError:error]){
            _actionBtn.hidden=NO;
            if(isFriend){
                [_actionBtn addTarget:self action:@selector(goChat) forControlEvents:UIControlEventTouchUpInside];
                [_actionBtn setTitle:@"开始聊天" forState:UIControlStateNormal];
            }else{
                [_actionBtn addTarget:self action:@selector(tryAddFriend) forControlEvents:UIControlEventTouchUpInside];
                [_actionBtn setTitle:@"添加好友" forState:UIControlStateNormal];
            }
        }
    }];
}

#pragma actions

-(void)goChat{
    [[CDIMService shareInstance] goWithUserId:self.user.objectId fromVC:self];
}

-(void)tryAddFriend{
    [CDUtils showNetworkIndicator];
    [CDUserService tryCreateAddRequestWithToUser:_user callback:^(BOOL succeeded, NSError *error) {
        [CDUtils hideNetworkIndicator];
        if([CDUtils filterError:error]){
            [CDUtils alert:@"请求成功"];
        }
    }];
}


@end

//
//  CDUserInfoController.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDUserInfoVC.h"
#import "CDAddRequestService.h"
#import "CDChatRoomVC.h"
#import "CDCloudService.h"
#import "CDCacheService.h"
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"详情";
    _nameLabel.text=_user.username;
    isFriend=[[CDCacheService getFriends] containsObject:_user];
    [_actionBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    if(isFriend){
        [_actionBtn setTitle:@"开始聊天" forState:UIControlStateNormal];
    }else{
        [_actionBtn setTitle:@"添加好友" forState:UIControlStateNormal];
    }
    imClient=[CDIM sharedInstance];

    [CDUserService displayAvatarOfUser:_user avatarView:self.avatarView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma actions

-(void)btnClicked:(UIButton*)button{
    if(isFriend){
        [CDChatRoomVC chatWithUserId:self.user.objectId fromVC:self];
    }else{
        [CDUtils showNetworkIndicator];
        [CDCloudService tryCreateAddRequestWithToUser:_user callback:^(id object, NSError *error) {
            [CDUtils hideNetworkIndicator];
            if(error.code==3840){
                [CDUtils alert:@"云代码未部署，请到项目主页根据说明来部署"];
                return ;
            }
            NSString *info;
            if(error==nil){
                info=@"请求成功";
            }else{
                info=[error localizedDescription];
            }
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NULL message:info delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }];
    }
}

@end

//
//  CDIMService.m
//  LeanChat
//
//  Created by lzw on 15/4/3.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDIMService.h"
#import "CDUser.h"

@interface CDIMService ()

@property (nonatomic,strong) CDIM* im;

@property (nonatomic,strong) CDChatRoomVC* chatRoomVC;

@end

@implementation CDIMService

+(instancetype)shareInstance{
    static CDIMService* imService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imService=[[CDIMService alloc] init];
    });
    return imService;
}

-(instancetype)init{
    self=[super init];
    if(self){
       self.im=[CDIM sharedInstance];
    }
    return self;
}

#pragma mark - user delegate

-(void)cacheUserByIds:(NSSet *)userIds block:(AVIMArrayResultBlock)block{
    block(nil,nil); // don't forget it
}

-(id<CDUserModel>)getUserById:(NSString *)userId{
    CDUser* user=[[CDUser alloc] init];
    user.userId=userId;
    user.username=userId;
    user.avatarUrl=@"http://ac-x3o016bx.clouddn.com/86O7RAPx2BtTW5zgZTPGNwH9RZD5vNDtPm1YbIcu";
    return user;
}

-(void)goWithConv:(AVIMConversation*)conv fromNav:(UINavigationController*)nav{
    self.chatRoomVC=[[CDChatRoomVC alloc] initWithConv:conv];
    self.chatRoomVC.hidesBottomBarWhenPushed=YES;
    UIImage* _peopleImage=[UIImage imageNamed:@"chat_menu_people"];
    UIBarButtonItem* item=[[UIBarButtonItem alloc] initWithImage:_peopleImage style:UIBarButtonItemStyleDone target:self action:@selector(goChatGroupDetail:)];
    self.chatRoomVC.navigationItem.rightBarButtonItem=item;
    [nav pushViewController:self.chatRoomVC animated:YES];
}

-(void)goWithUserId:(NSString*)userId fromVC:(UIViewController*)vc {
    CDIM* im=[CDIM sharedInstance];
    [im fetchConvWithUserId:userId callback:^(AVIMConversation *conversation, NSError *error) {
        if(error){
            DLog(@"%@",error);
        }else{
            [self goWithConv:conversation fromNav:vc.navigationController];
        }
    }];
}

- (void)goChatGroupDetail:(id)sender {
    DLog(@"click");
}


@end

//
//  MainViewController.m
//  LeanChatExample
//
//  Created by lzw on 15/4/3.
//  Copyright (c) 2015年 avoscloud. All rights reserved.
//

#import "MainViewController.h"
#import "LCECommon.h"
#import "LCEChatRoomVC.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UITextField *otherIdTextField;


@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.otherIdTextField.text=@"b";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
}

-(void)dealloc{
    [[CDIM sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
        DLog(@"%@",error);
    }];
}

- (IBAction)goChat:(id)sender {
    NSString* otherId=self.otherIdTextField.text;
    if(otherId.length>0){
        WEAKSELF
        [[CDIM sharedInstance] fetchConvWithUserId:otherId callback:^(AVIMConversation *conversation, NSError *error) {
            if(error){
                DLog(@"%@",error);
            }else{
                LCEChatRoomVC* chatRoomVC=[[LCEChatRoomVC alloc] initWithConv:conversation];
                [weakSelf.navigationController pushViewController:chatRoomVC animated:YES];
            }
        }];
    }
}

@end

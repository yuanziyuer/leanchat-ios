//
//  MainViewController.m
//  LeanChatExample
//
//  Created by lzw on 15/4/3.
//  Copyright (c) 2015年 avoscloud. All rights reserved.
//

#import "MainViewController.h"
#import "LCECommon.h"
#import "CDIMService.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UITextField *otherIdTextField;


@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.otherIdTextField.text=@"b";
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
    if(self.otherIdTextField.text.length>0){
        [[CDIMService shareInstance] goWithUserId:self.otherIdTextField.text fromVC:self];
    }
}

@end

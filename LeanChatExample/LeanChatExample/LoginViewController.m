//
//  ViewController.m
//  LeanChatExample
//
//  Created by lzw on 15/4/3.
//  Copyright (c) 2015年 avoscloud. All rights reserved.
//

#import "LoginViewController.h"
#import "CDUserFactory.h"
#import "LCEChatListVC.h"
#import "AppDelegate.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *selfIdTextField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)login:(id)sender {
    NSString *selfId = self.selfIdTextField.text;
    if (selfId.length > 0) {
        [[CDChatManager manager] openWithClientId:selfId callback: ^(BOOL succeeded, NSError *error) {
            if (error) {
                DLog(@"%@", error);
            }
            else {
                UITabBarController *tabbarController = [[UITabBarController alloc] init];
                LCEChatListVC *chatListVC = [[LCEChatListVC alloc] init];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:chatListVC];
                [tabbarController addChildViewController:nav];
                AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
                appDelegate.window.rootViewController = tabbarController;
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

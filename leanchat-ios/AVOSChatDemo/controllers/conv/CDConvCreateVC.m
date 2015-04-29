//
//  CDNewGroupViewController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDConvCreateVC.h"
#import "CDUtils.h"

@interface CDConvCreateVC ()
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@end

@implementation CDConvCreateVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title=@"创建群组";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(createNewGroup)];
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(backPressed)];
}

-(void)backPressed{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)createNewGroup{
    NSString* name=[self.nameTextField text];
    if([name length]>0){
        UIActivityIndicatorView* indicator=[CDUtils showIndicatorAtView:self.view];
//        [CDGroupService saveNewGroupWithName:name withCallback:^(AVGroup *group, NSError *error) {
//            [indicator stopAnimating];
//            if(error){
//                [CDUtils alertError:error];
//            }else{
//                [self backPressed];
//                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_GROUP_UPDATED object:self];
//            }
//        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

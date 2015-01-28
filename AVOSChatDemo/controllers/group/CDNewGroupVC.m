//
//  CDNewGroupViewController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDNewGroupVC.h"
#import "CDSessionManager.h"
#import "CDUtils.h"
#import "CDGroupService.h"

@interface CDNewGroupVC ()
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@end

@implementation CDNewGroupVC

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
        CDSessionManager* man=[CDSessionManager sharedInstance];
        [CDGroupService saveNewGroupWithName:name withCallback:^(AVGroup *group, NSError *error) {
            [indicator stopAnimating];
            if(error){
                [CDUtils alertError:error];
            }else{
                [self backPressed];
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_GROUP_UPDATED object:self];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  CDNewGroupViewController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDNewGroupViewController.h"
#import "CDSessionManager.h"
#import "Utils.h"

@interface CDNewGroupViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@end

@implementation CDNewGroupViewController

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
        UIActivityIndicatorView* indicator=[Utils showIndicatorAtView:self.view];
        CDSessionManager* man=[CDSessionManager sharedInstance];
        [man saveNewGroupWithName:name withCallback:^(AVGroup *group, NSError *error) {
            [indicator stopAnimating];
            if(error){
                [Utils alertError:error];
            }else{
                [self backPressed];
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

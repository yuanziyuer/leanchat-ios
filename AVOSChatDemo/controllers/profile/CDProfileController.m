//
//  CDProfileController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDProfileController.h"
#import "CDCommon.h"
#import "CDLoginController.h"
#import "CDAppDelegate.h"
#import "CDSessionManager.h"
#import "ResizableButton.h"

@interface CDProfileController ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITableViewCell *avatarCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *logoutCell;

@end

@implementation CDProfileController

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"我";
        self.tabBarItem.image = [UIImage imageNamed:@"tabbar_me_active"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AVUser *user = [AVUser currentUser];
    NSString *username = [user username];
    if ([user mobilePhoneVerified]) {
        username = [NSString stringWithFormat:@"%@(%@)", username, [user mobilePhoneNumber]];
    }
    self.nameLabel.text = username;
    UIImageView* imageView=self.avatarView;
//    imageView.layer.cornerRadius=10;
//    imageView.layer.masksToBounds = YES;
    
    [CDUserService displayAvatarOfUser:user avatarView:self.avatarView];
    //_tableView.autoresizingMask=UIViewAutoresizingFlexibleHeight;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

-(void)logout {
    [[CDSessionManager sharedInstance] clearData];
    [AVUser logOut];
    CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate toLogin];
}

#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    int section=indexPath.section;
    switch (section) {
        case 0:
            _avatarCell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            return _avatarCell;
        case 1:
            _logoutCell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            return _logoutCell;
        default:
            return nil;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    int section=indexPath.section;
    if(section==0){
        [self pickImageFromPhotoLibrary];
    }else if(section==1){
        [self logout];
    }
}

-(void)pickImageFromPhotoLibrary{
    UIImagePickerControllerSourceType srcType=UIImagePickerControllerSourceTypePhotoLibrary;
    NSArray* mediaTypes=[UIImagePickerController availableMediaTypesForSourceType:srcType];
    if([UIImagePickerController isSourceTypeAvailable:srcType] && [mediaTypes count]>0){
        UIImagePickerController* ctrler=[[UIImagePickerController alloc] init];
        ctrler.mediaTypes=mediaTypes;
        ctrler.delegate=self;
        ctrler.allowsEditing=YES;
        ctrler.sourceType=srcType;
        [self presentViewController:ctrler animated:YES completion:nil];
    }else{
        [CDUtils alert:@"no image picker available"];
    }
}

#pragma mark - image picker delegate


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:YES completion:^{
        UIActivityIndicatorView* indicator=[CDUtils showIndicatorAtView:self.view];
        UIImage* image=info[UIImagePickerControllerEditedImage];
        UIImage* rounded=[CDUtils roundImage:image toSize:CGSizeMake(200, 200) radius:20];
        [CDUserService saveAvatar:rounded callback:^(BOOL succeeded, NSError *error) {
            [indicator stopAnimating];
            [CDUtils filterError:error callback:^{
                self.avatarView.image=rounded;
            }];
        }];
    }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

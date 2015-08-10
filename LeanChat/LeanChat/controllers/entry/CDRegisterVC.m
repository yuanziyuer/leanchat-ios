//
//  CDRegisterController.m
//  LeanChat
//
//  Created by Qihe Bian on 7/24/14.
//  Copyright (c) 2014 LeanCloud. All rights reserved.
//

#import "CDRegisterVC.h"
#import "CDAppDelegate.h"
#import "CDEntryActionButton.h"
#import "CDPhoneRegisterVC.h"

static CGFloat const phoneButtonSize = 40;

@interface CDRegisterVC () <CDEntryVCDelegate>

@property (nonatomic, strong) UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, strong) CDEntryActionButton *registerButton;
@property (nonatomic, strong) UIButton *phoneButton;

@end

@implementation CDRegisterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"注册";
    self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
    [self.view addSubview:self.registerButton];
    [self.view addSubview:self.phoneButton];
    
    [self phoneButtonClicked:nil];
}

- (UIBarButtonItem *)cancelBarButtonItem {
    if (_cancelBarButtonItem == nil) {
        UIImage *image = [UIImage imageNamed:@"cancel"];
        UIImage *selectedImage = [UIImage imageNamed:@"cancel_selected"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:selectedImage forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        _cancelBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return _cancelBarButtonItem;
}

- (UIButton *)registerButton {
    if (_registerButton == nil) {
        _registerButton = [[CDEntryActionButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.usernameField.frame), CGRectGetMaxY(self.passwordField.frame) + kEntryVCVerticalSpacing, CGRectGetWidth(self.usernameField.frame), CGRectGetHeight(self.usernameField.frame))];
        _registerButton.enabled = NO;
        [_registerButton setTitle:@"注册" forState:UIControlStateNormal];
        [_registerButton addTarget:self action:@selector(registerAVUser:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _registerButton;
}

- (UIButton *)phoneButton {
    if (_phoneButton == nil) {
        _phoneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, phoneButtonSize, phoneButtonSize)];
        _phoneButton.center = CGPointMake(CGRectGetMidX(self.registerButton.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navigationController.navigationBar.frame) - kEntryVCVerticalSpacing * 3  - phoneButtonSize / 2);
        [_phoneButton setImage:[UIImage imageNamed:@"register_phone"] forState:UIControlStateNormal];
        _phoneButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        _phoneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        [_phoneButton addTarget:self action:@selector(phoneButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _phoneButton;
}

#pragma mark - Actions

- (void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion: ^{
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }];
}

- (void)registerAVUser:(id)sender {
    AVUser *user = [AVUser user];
    user.username = self.usernameField.text;
    user.password = self.passwordField.text;
    [user setFetchWhenSave:YES];
    WEAKSELF
    [user signUpInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
        if ([weakSelf filterError:error]) {
            [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:KEY_USERNAME];
            [weakSelf dismissViewControllerAnimated:NO completion: ^{
                CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
                [delegate toMain];
            }];
        }
    }];
}

- (void)phoneButtonClicked:(id)sender {
    CDPhoneRegisterVC *vc = [[CDPhoneRegisterVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)changeButtonState {
    if (self.usernameField.text.length >= USERNAME_MIN_LENGTH && self.passwordField.text.length >= PASSWORD_MIN_LENGTH) {
        self.registerButton.enabled = YES;
    }
    else {
        self.registerButton.enabled = NO;
    }
}

- (void)didPasswordTextFieldReturn:(CDTextField *)passwordField {
    if (self.registerButton.enabled) {
        [self registerAVUser:nil];
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self changeButtonState];
}

@end

//
//  CDEntryVC.m
//  LeanChat
//
//  Created by lzw on 15/4/15.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDEntryVC.h"
#import "CDTextField.h"

@interface CDEntryVC () <UITextFieldDelegate, CDEntryVCDelegate>

@property (nonatomic, assign) CGPoint originOffset;

@end

@implementation CDEntryVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    //[self.view setBackgroundColor:RGBCOLOR(222, 223, 225)];
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.iconImageView];
    [self.view addSubview:self.usernameField];
    [self.view addSubview:self.passwordField];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _originOffset = self.view.frame.origin;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Propertys

- (UIImageView *)backgroundImageView {
    if (_backgroundImageView == nil) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        _backgroundImageView.image = [UIImage imageNamed:@"login_background"];
    }
    return _backgroundImageView;
}

- (UIImageView *)iconImageView {
    if (_iconImageView == nil) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - kEntryVCIconImageViewSize / 2, kEntryVCIconImageViewMarginTop, kEntryVCIconImageViewSize, kEntryVCIconImageViewSize)];
        _iconImageView.image = [UIImage imageNamed:@"rounded_icon"];
    }
    return _iconImageView;
}

- (CDTextField *)usernameField {
    if (_usernameField == nil) {
        _usernameField = [[CDTextField alloc] initWithFrame:CGRectMake(kEntryVCHorizontalSpacing, CGRectGetMaxY(_iconImageView.frame) + kEntryVCUsernameFieldMarginTop, CGRectGetWidth(self.view.frame) - kEntryVCHorizontalSpacing * 2, kEntryVCTextFieldHeight)];
        _usernameField.background = [UIImage imageNamed:@"input_bg_top"];
        _usernameField.horizontalPadding = kEntryVCTextFieldPadding;
        _usernameField.verticalPadding = kEntryVCTextFieldPadding;
        _usernameField.placeholder = @"用户名";
        _usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _usernameField.delegate = self;
        _usernameField.returnKeyType = UIReturnKeyNext;
        _usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    return _usernameField;
}

- (CDTextField *)passwordField {
    if (_passwordField == nil) {
        _passwordField = [[CDTextField alloc] initWithFrame:CGRectMake(CGRectGetMinX(_usernameField.frame), CGRectGetMaxY(_usernameField.frame), CGRectGetWidth(_usernameField.frame), CGRectGetHeight(_usernameField.frame))];
        _passwordField.background = [UIImage imageNamed:@"input_bg_bottom"];
        _passwordField.horizontalPadding = kEntryVCTextFieldPadding;
        _passwordField.verticalPadding = kEntryVCTextFieldPadding;
        _passwordField.delegate = self;
        _passwordField.textAlignment = UIControlContentHorizontalAlignmentCenter;
        _passwordField.placeholder = @"密码";
        _passwordField.secureTextEntry = YES;
        _passwordField.returnKeyType = UIReturnKeyGo;
        _passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    return _passwordField;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    }
    else if (textField == self.passwordField) {
        [self didPasswordTextFieldReturn:(CDTextField *)textField];
    }
    return YES;
}

- (void)didPasswordTextFieldReturn:(CDTextField *)passwordField {
    // subclass
}

- (void)textFieldDidChange:(UITextField *)textField {
    //subclass
}

- (void)closeKeyboard:(id)sender {
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

@end

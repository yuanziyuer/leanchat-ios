//
//  CDPhoneRegisterVC.m
//  LeanChat
//
//  Created by lzw on 15/8/10.
//  Copyright (c) 2015年 lzwjava@LeanCloud QQ: 651142978. All rights reserved.
//

#import <LZAlertViewHelper/LZAlertViewHelper.h>
#import "CDPhoneRegisterVC.h"
#import "CDTextField.h"
#import "CDResizableButton.h"
#import "CDEntryActionButton.h"
#import "CDAppDelegate.h"

static CGFloat const kCodeTextFieldMarginButton = 10;
static CGFloat const kCodeTextFieldScale = 0.6;
static CGFloat const kTextFieldMarginTop = 30;

@interface CDPhoneRegisterVC ()

@property (nonatomic, copy) NSString *phone;
@property (nonatomic) CDTextField *phoneTextField;
@property (nonatomic) CDTextField *codeTextField;
@property (nonatomic) CDResizableButton *smsCodeButton;
@property (nonatomic) CDResizableButton *registerButton;
@property (nonatomic) NSTimer *timer;
@property (nonatomic, assign) NSInteger remainingTicks;
@property (nonatomic) LZAlertViewHelper *alertViewHelper;

@end

@implementation CDPhoneRegisterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"手机号注册";
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.phoneTextField];
    [self.view addSubview:self.codeTextField];
    [self.view addSubview:self.smsCodeButton];
    [self.view addSubview:self.registerButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - Propertys

- (LZAlertViewHelper *)alertViewHelper {
    if (_alertViewHelper == nil) {
        _alertViewHelper = [[LZAlertViewHelper alloc] init];
    }
    return _alertViewHelper;
}

- (CDTextField *)phoneTextField {
    if (_phoneTextField == nil) {
        _phoneTextField = [CDTextField textFieldWithPadding:kEntryVCTextFieldPadding];
        _phoneTextField.frame = CGRectMake(kEntryVCHorizontalSpacing, kTextFieldMarginTop, CGRectGetWidth(self.view.frame) - 2 * kEntryVCHorizontalSpacing, kEntryVCTextFieldHeight);
        _phoneTextField.background = [UIImage imageNamed:@"input_bg_top"];
        _phoneTextField.placeholder = @"请输入手机号";
        _phoneTextField.keyboardType = UIKeyboardTypeNumberPad;
    }
    return _phoneTextField;
}

- (CDTextField *)codeTextField {
    if (_codeTextField == nil) {
        CGFloat width = CGRectGetWidth(self.phoneTextField.frame) * kCodeTextFieldScale;
        _codeTextField = [CDTextField textFieldWithPadding:kEntryVCTextFieldPadding];
        _codeTextField.frame = CGRectMake(CGRectGetMinX(self.phoneTextField.frame), CGRectGetMaxY(self.phoneTextField.frame) + kEntryVCVerticalSpacing, width, kEntryVCTextFieldHeight);
        _codeTextField.background = [UIImage imageNamed:@"input_bg_bottom"];
        _codeTextField.placeholder = @"验证码";
        _codeTextField.keyboardType = UIKeyboardTypeNumberPad;
    }
    return _codeTextField;
}

- (CDResizableButton *)smsCodeButton {
    if (_smsCodeButton == nil) {
        _smsCodeButton = [[CDEntryActionButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.codeTextField.frame) + kCodeTextFieldMarginButton, CGRectGetMinY(self.codeTextField.frame), CGRectGetWidth(self.phoneTextField.frame) - CGRectGetWidth(self.codeTextField.frame) - kCodeTextFieldMarginButton, kEntryVCTextFieldHeight)];
        _smsCodeButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_smsCodeButton setTitle:@"请求验证码" forState:UIControlStateNormal];
        [_smsCodeButton addTarget:self action:@selector(smsCodeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _smsCodeButton;
}

- (UIButton *)registerButton {
    if (_registerButton == nil) {
        _registerButton = [[CDEntryActionButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.phoneTextField.frame), CGRectGetMaxY(self.codeTextField.frame) + kEntryVCVerticalSpacing, CGRectGetWidth(self.phoneTextField.frame), CGRectGetHeight(self.phoneTextField.frame))];
        [_registerButton setTitle:@"注册" forState:UIControlStateNormal];
        [_registerButton addTarget:self action:@selector(registerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _registerButton;
}

#pragma mark - Actions

- (void)smsCodeButtonClicked:(id)sender {
    NSString *phone = self.phoneTextField.text;
    if (phone.length > 0) {
        // 服务端会检查
        self.smsCodeButton.enabled = NO;
        [AVOSCloud requestSmsCodeWithPhoneNumber:phone appName:@"LeanChat" operation:@"注册" timeToLive:10 callback: ^(BOOL succeeded, NSError *error) {
            if ([self filterError:error]) {
                [self sendCodeSucceedWithPhone:phone];
            } else {
                self.smsCodeButton.enabled = YES;
            }
        }];
    } else {
        [self toast:@"请输入手机号码"];
    }
}

- (void)sendCodeSucceedWithPhone:(NSString *)phone {
    self.smsCodeButton.enabled = NO;
    self.phone = phone;
    self.remainingTicks = 60;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerHit:) userInfo:nil repeats:YES];
}

- (void)timerHit:(id)sender {
    self.remainingTicks--;
    [self updateButton];
    if (self.remainingTicks <= 0) {
        [self.timer invalidate];
        self.timer = nil;
        self.smsCodeButton.enabled = YES;
        [self.smsCodeButton setTitle:@"请求验证码" forState:UIControlStateNormal];
    }
}

- (void)updateButton {
    [self.smsCodeButton setTitle:[NSString stringWithFormat:@"等待%ld秒", self.remainingTicks] forState:UIControlStateNormal];
}

- (void)registerButtonClicked:(id)sender {
    NSString *code = self.codeTextField.text;
    if (code.length > 0 && self.phone.length > 0) {
        // 需要在控制台设置选项开启权限
        [AVOSCloud verifySmsCode:code mobilePhoneNumber:self.phone callback:^(BOOL succeeded, NSError *error) {
            if ([self filterError:error]) {
                [self.alertViewHelper showInputAlertViewWithMessage:@"验证成功！只差一步了，设置一个密码，以便下次能以手机号和密码登录" block:^(BOOL confirm, NSString *text) {
                    if (confirm) {
                        AVUser *user = [AVUser user];
                        user.username = self.phone;
                        user.password = text;
                        user.mobilePhoneNumber = self.phone;
                        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if([self filterError:error]) {
                                CDAppDelegate *app = [UIApplication sharedApplication].delegate;
                                [app toMain];
                            }
                        }];
                    }
                }];
            }
        }];
    } else {
        [self showHUDText:@"请完善信息"];
    }
}


@end

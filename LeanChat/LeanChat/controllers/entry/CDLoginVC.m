//
//  CDLoginController.m
//  LeanChat
//
//  Created by Qihe Bian on 7/24/14.
//  Copyright (c) 2014 LeanCloud. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <LeanCloudSocial/AVOSCloudSNS.h>
#import <LZAlertViewHelper/LZAlertViewHelper.h>

#import "CDLoginVC.h"
#import "CDRegisterVC.h"
#import "CDAppDelegate.h"
#import "CDEntryBottomButton.h"
#import "CDEntryActionButton.h"
#import "CDBaseNavC.h"
#import "CDSNSView.h"

@interface CDLoginVC () <CDEntryVCDelegate, CDSNSViewDelegate>

@property (nonatomic, strong) LZAlertViewHelper *alertViewHelper;

@property (nonatomic, strong) CDEntryActionButton *loginButton;
@property (nonatomic, strong) CDEntryBottomButton *registerButton;
@property (nonatomic, strong) CDEntryBottomButton *forgotPasswordButton;
@property (nonatomic, strong) CDSNSView *snsView;

@end

@implementation CDLoginVC

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [AVOSCloudSNS setupPlatform:AVOSCloudSNSQQ withAppKey:QQAppId andAppSecret:QQAppKey andRedirectURI:nil];
    [AVOSCloudSNS setupPlatform:AVOSCloudSNSSinaWeibo withAppKey:WeiboAppId andAppSecret:WeiboAppKey andRedirectURI:@"http://wanpaiapp.com/oauth/callback/sina"];
    [AVOSCloudSNS setupPlatform:AVOSCloudSNSWeiXin withAppKey:WeChatAppId andAppSecret:WeChatSecretKey andRedirectURI:nil];
    
    [self.view addSubview:self.loginButton];
    [self.view addSubview:self.registerButton];
    [self.view addSubview:self.forgotPasswordButton];
    [self.view addSubview:self.snsView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.usernameField.text = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USERNAME];
    [self changeButtonState];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Propertys

- (CDResizableButton *)loginButton {
    if (_loginButton == nil) {
        _loginButton = [[CDEntryActionButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.usernameField.frame), CGRectGetMaxY(self.passwordField.frame) + kEntryVCVerticalSpacing, CGRectGetWidth(self.usernameField.frame), CGRectGetHeight(self.usernameField.frame))];
        [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
        _loginButton.enabled = NO;
        [_loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _loginButton;
}

- (UIButton *)registerButton {
    if (_registerButton == nil) {
        _registerButton = [[CDEntryBottomButton alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - kEntryVCTextFieldHeight, CGRectGetWidth(self.view.frame) / 2, kEntryVCTextFieldHeight)];
        [_registerButton setTitle:@"注册账号" forState:UIControlStateNormal];
        [_registerButton addTarget:self action:@selector(toRegister:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _registerButton;
}

- (UIButton *)forgotPasswordButton {
    if (_forgotPasswordButton == nil) {
        _forgotPasswordButton = [[CDEntryBottomButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(self.view.frame) - kEntryVCTextFieldHeight, CGRectGetWidth(self.view.frame) / 2, kEntryVCTextFieldHeight)];
        [_forgotPasswordButton setTitle:@"找回密码" forState:UIControlStateNormal];
        [_forgotPasswordButton addTarget:self action:@selector(toFindPassword:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _forgotPasswordButton;
}

- (CDSNSView *)snsView {
    if (_snsView == nil) {
        NSMutableArray *displayTypes = [NSMutableArray arrayWithObjects:@(CDSNSTypeQQ), @(CDSNSTypeWeibo), nil];
        if ([AVOSCloudSNS isAppInstalledForType:AVOSCloudSNSWeiXin]) {
            [displayTypes addObject:@(CDSNSTypeWeiXin)];
        }
        CGSize size = [CDSNSView sizeForDisplayTypes:displayTypes];
        _snsView = [[CDSNSView alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - size.width / 2, CGRectGetMinY(self.registerButton.frame) - kEntryVCVerticalSpacing - size.height , size.width, size.height)];
        _snsView.displayTypes = displayTypes;
        _snsView.delegate = self;
        [_snsView reloadData];
    }
    return _snsView;
}

- (LZAlertViewHelper *)alertViewHelper {
    if (_alertViewHelper == nil) {
        _alertViewHelper = [[LZAlertViewHelper alloc] init];
    }
    return _alertViewHelper;
}

#pragma mark - Actions
- (void)login:(id)sender {
    [AVUser logInWithUsernameInBackground:self.usernameField.text password:self.passwordField.text block: ^(AVUser *user, NSError *error) {
        if (error) {
            [self showHUDText:error.localizedDescription];
        }
        else {
            [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:KEY_USERNAME];
            CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
            [delegate toMain];
        }
    }];
}

- (void)toRegister:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    CDRegisterVC *vc = [[CDRegisterVC alloc] init];
    CDBaseNavC *nav = [[CDBaseNavC alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)changeButtonState {
    if (self.usernameField.text.length >= USERNAME_MIN_LENGTH && self.passwordField.text.length >= PASSWORD_MIN_LENGTH) {
        self.loginButton.enabled = YES;
    }
    else {
        self.loginButton.enabled = NO;
    }
}

- (void)toFindPassword:(id)sender {
    [self showHUDText:@"鞭打工程师中..."];
}

- (void)didPasswordTextFieldReturn:(CDTextField *)passwordField {
    if (self.registerButton.enabled) {
        [self login:nil];
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self changeButtonState];
}

#pragma mark - sso util


- (void)loginWithAuthData:(NSDictionary *)authData platform:(NSString *)platform {
    __block NSString *username = authData[@"username"];
    __block NSString *avatar = authData[@"avatar"];
    [AVUser loginWithAuthData:authData platform:platform block:^(AVUser *user, NSError *error) {
        if ([self filterError:error]) {
            if (user.updatedAt) {
                // 之前已经登录过、设置好用户名和头像了
                CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
                [delegate toMain];
            } else {
                if (username) {
                    [self countUserByUsername:username block:^(NSInteger number, NSError *error) {
                        if ([self filterError:error]) {
                            if (number > 0) {
                                // 用户名重复了，给一个随机的后缀
                                username = [NSString stringWithFormat:@"%@%@",username, [[CDUtils uuid] substringToIndex:3]];
                                [self changeToUsername:username avatar:avatar user:user];
                            } else {
                                [self changeToUsername:username avatar:avatar user:user];
                            }
                        }
                    }];
                } else {
                    // 应该不可能出现这种情况
                    // 没有名字，只改头像
                    [self changeToUsername:nil avatar:avatar user:user];
                }
            }
        }
    }];
}

- (void)countUserByUsername:(NSString *)username block:(AVIntegerResultBlock)block {
    AVQuery *q = [AVUser query];
    [q whereKey:@"username" equalTo:username];
    [q countObjectsInBackgroundWithBlock:block];
}

- (void)saveAvatar:(NSString *)url block:(AVFileResultBlock)block {
    if (!url) {
        block(nil, nil);
    } else {
        AVFile *file = [AVFile fileWithURL:url];
        [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                block(nil, error);
            } else {
                block(file, nil);
            }
        }];
    }
}

- (void)changeToUsername:(NSString *)username avatar:(NSString *)avatar user:(AVUser *)user {
    [self saveAvatar:avatar block:^(AVFile *file, NSError *error) {
        if (file) {
            [user setObject:file forKey:@"avatar"];
        }
        if (username) {
            user.username = username;
        }
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if ([self filterError:error]){
                CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
                [delegate toMain];
            }
        }];
    }];
}

#pragma mark - sns login button clicked

- (BOOL)filterError:(NSError *)error {
    if (error.code == AVOSCloudSNSErrorUserCancel) {
        [self showHUDText:@"取消了登录"];
        return NO;
    }
    return [super filterError:error];
}

- (void)snsView:(CDSNSView *)snsView buttonClickedForType:(CDSNSType)type {
    NSString *platform;
    AVOSCloudSNSType snsType;
    switch (type) {
        case CDSNSTypeQQ: {
            snsType = AVOSCloudSNSQQ;
            platform = AVOSCloudSNSPlatformQQ;
            break;
        }
        case CDSNSTypeWeiXin: {
            snsType = AVOSCloudSNSWeiXin;
            platform = AVOSCloudSNSPlatformWeiXin;
            break;
        }
        case CDSNSTypeWeibo: {
            snsType = AVOSCloudSNSSinaWeibo;
            platform = AVOSCloudSNSPlatformWeiBo;
            break;
        }
    }
    [AVOSCloudSNS loginWithCallback:^(id object, NSError *error) {
        if ([self filterError:error]) {
            [self loginWithAuthData:object platform:platform];
        }
    } toPlatform:snsType];
}

@end

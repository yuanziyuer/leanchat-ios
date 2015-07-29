//
//  CDLoginController.m
//  LeanChat
//
//  Created by Qihe Bian on 7/24/14.
//  Copyright (c) 2014 LeanCloud. All rights reserved.
//

#import "CDLoginVC.h"
#import "CDRegisterVC.h"
#import "CDAppDelegate.h"
#import "CDEntryBottomButton.h"
#import "CDEntryActionButton.h"
#import "CDBaseNavC.h"
#import <AFNetworking/AFNetworking.h>
#import <LeanCloudSocial/AVOSCloudSNS.h>
#import <LZAlertViewHelper/LZAlertViewHelper.h>

#define WeChatAppId @"wxa3eacc1c86a717bc"
#define WeChatSecretKey @"b5bf245970b2a451fb8cebf8a6dff0c1"
#define QQAppId @"1104788666"
#define QQAppKey @"dOVWmsD7bW0zlyTV"

static CGFloat const kCDSNSButtonSize = 35;
static CGFloat const kCDSNSButtonMargin = 15;

@interface CDLoginVC () <CDEntryVCDelegate>

@property (nonatomic, strong) LZAlertViewHelper *alertViewHelper;

@property (nonatomic, strong) CDEntryActionButton *loginButton;
@property (nonatomic, strong) CDResizableButton *wechatLoginButton;
@property (nonatomic, strong) CDResizableButton *qqButton;
@property (nonatomic, strong) CDResizableButton *weiboButton;
@property (nonatomic, strong) CDEntryBottomButton *registerButton;
@property (nonatomic, strong) CDEntryBottomButton *forgotPasswordButton;

@end

@implementation CDLoginVC

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [WXApi registerApp:WeChatAppId withDescription:@"LeanChat"];
    [AVOSCloudSNS setupPlatform:AVOSCloudSNSQQ withAppKey:QQAppId andAppSecret:QQAppKey andRedirectURI:nil];
    [AVOSCloudSNS setupPlatform:AVOSCloudSNSSinaWeibo withAppKey:@"2548122881" andAppSecret:@"ba37a6eb3018590b0d75da733c4998f8" andRedirectURI:@"http://wanpaiapp.com/oauth/callback/sina"];
    
    [self.view addSubview:self.loginButton];
    [self.view addSubview:self.registerButton];
    [self.view addSubview:self.forgotPasswordButton];
    [self.view addSubview:self.wechatLoginButton];
    [self.view addSubview:self.qqButton];
    [self.view addSubview:self.weiboButton];
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


- (CDResizableButton *)wechatLoginButton {
    if (_wechatLoginButton == nil) {
        _wechatLoginButton = [[CDResizableButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.usernameField.frame) - kCDSNSButtonSize / 2, CGRectGetMinY(self.registerButton.frame) - kCDSNSButtonMargin - kCDSNSButtonSize, kCDSNSButtonSize, kCDSNSButtonSize)];
        [_wechatLoginButton setImage:[UIImage imageNamed:@"sns_wechat"] forState:UIControlStateNormal];
        [_wechatLoginButton addTarget:self action:@selector(wechatButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _wechatLoginButton;
}

- (CDResizableButton *)qqButton {
    if (_qqButton == nil) {
        _qqButton = [[CDResizableButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.wechatLoginButton.frame) - kCDSNSButtonMargin -kCDSNSButtonSize, CGRectGetMinY(self.wechatLoginButton.frame), kCDSNSButtonSize, kCDSNSButtonSize)];
        [_qqButton setImage:[UIImage imageNamed:@"sns_qq"] forState:UIControlStateNormal];
        [_qqButton addTarget:self action:@selector(qqButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _qqButton;
}

- (CDResizableButton *)weiboButton {
    if (_weiboButton == nil) {
        _weiboButton = [[CDResizableButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.wechatLoginButton.frame) + kCDSNSButtonMargin, CGRectGetMinY(self.wechatLoginButton.frame), kCDSNSButtonSize, kCDSNSButtonSize)];
        [_weiboButton setImage:[UIImage imageNamed:@"sns_weibo"] forState:UIControlStateNormal];
        [_weiboButton addTarget:self action:@selector(weiboButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _weiboButton;
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

#pragma mark - wechat 
- (void)wechatButtonClicked:(id)sender {
    SendAuthReq* req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo"; // @"post_timeline,sns"
    req.state = @"leanchat_state";
    req.openID = WeChatAppId;
    [WXApi sendAuthReq:req viewController:self delegate:self];
}

-(void) onReq:(BaseReq*)req {
    DLog();
}

-(void) onResp:(BaseResp*)resp {
    DLog(@"%@", resp);
    if (resp.errCode == WXSuccess) {
        if ([resp isKindOfClass:[SendAuthResp class]]) {
            SendAuthResp *authResp = (SendAuthResp *)resp;
            NSDictionary *params = @{@"appid":WeChatAppId, @"secret": WeChatSecretKey, @"code":authResp.code, @"grant_type":@"authorization_code"};
            AFHTTPRequestOperationManager *manager=                          [AFHTTPRequestOperationManager manager];
            manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
            [manager GET:@"https://api.weixin.qq.com/sns/oauth2/access_token" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if ([responseObject objectForKey:@"access_token"]) {
                    NSMutableDictionary *authData = [NSMutableDictionary dictionary];
                    [authData setObject:[responseObject objectForKey:@"openid"] forKey:@"openid"];
                    [authData setObject:[responseObject objectForKey:@"expires_in"] forKey:@"expires_in"];
                    [authData setObject:[responseObject objectForKey:@"access_token"] forKey:@"access_token"];
                    [self loginWithAuthData:authData platform:AVOSCloudSNSPlatformWeiXin];
                } else {
                    [self alert:[responseObject objectForKey:@"errmsg"]];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DLog();
            }];
        }
    } else {
        DLog(@"failed");
    }
}

- (void)loginWithAuthData:(NSDictionary *)authData platform:(NSString *)platform{
    [AVUser loginWithAuthData:authData platform:platform block:^(AVUser *user, NSError *error) {
        if ([self filterError:error]) {
            if (user.updatedAt) {
                // 之前已经登录过了
                CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
                [delegate toMain];
            } else {
                [self.alertViewHelper showInputAlertViewWithMessage:@"只差一步啦，请输入一个用户名" block:^(BOOL confirm, NSString *text) {
                    if (confirm) {
                        [self changeToUsername:text user:user];
                    }
                }];
            }
        }
    }];
}

- (void)changeToUsername:(NSString *)username user:(AVUser *)user {
    user.username = username;
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error.code == kAVErrorUsernameTaken) {
            [self askToInputAnotherUsenameWithUser:user];
        } else if ([self filterError:error]){
            CDAppDelegate *delegate = (CDAppDelegate *)[UIApplication sharedApplication].delegate;
            [delegate toMain];
        }
    }];
}

- (void)askToInputAnotherUsenameWithUser:(AVUser *)user {
    [self.alertViewHelper showInputAlertViewWithMessage:@"对不起，用户名重复了，请重新输入" block:^(BOOL confirm, NSString *text) {
        if (confirm) {
            [self changeToUsername:text user:user];
        }
    }];
}

#pragma mark - qq login
- (void)qqButtonClicked:(id)sender {
    [AVOSCloudSNS loginWithCallback:^(id object, NSError *error) {
        if ([self filterError:error]) {
            [self loginWithAuthData:object platform:AVOSCloudSNSPlatformQQ];
        }
    } toPlatform:AVOSCloudSNSQQ];
}

- (void)weiboButtonClicked:(id)sender {
    [AVOSCloudSNS loginWithCallback:^(id object, NSError *error) {
        if ([self filterError:error]) {
            [self loginWithAuthData:object platform:AVOSCloudSNSPlatformWeiBo];
        }
    } toPlatform:AVOSCloudSNSSinaWeibo];
}


@end

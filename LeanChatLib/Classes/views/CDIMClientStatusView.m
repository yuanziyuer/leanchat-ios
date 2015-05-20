//
//  CDNetworkStateView.m
//  LeanChat
//
//  Created by lzw on 15/1/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDIMClientStatusView.h"
#import "CDReachability.h"
#import "CDIM.h"

static CGFloat kCDAlertImageViewHeight = 20;
static CGFloat kCDHorizontalSpacing = 15;
static CGFloat kCDHorizontalLittleSpacing = 5;

@interface CDIMClientStatusView ()

@property (nonatomic, strong) CDNotify *notify;

@property (nonatomic, strong) UIImageView *alertImageView;

@property (nonatomic, strong) UILabel *alertLabel;

@end

@implementation CDIMClientStatusView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:199 / 255.0 blue:199 / 255.0 alpha:1];
        [self addSubview:self.alertImageView];
        [self addSubview:self.alertLabel];
    }
    return self;
}

#pragma mark - Propertys

- (UIImageView *)alertImageView {
    if (_alertImageView == nil) {
        _alertImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kCDHorizontalSpacing, (kCDIMClientStatusViewHight - kCDAlertImageViewHeight) / 2, kCDAlertImageViewHeight, kCDAlertImageViewHeight)];
        _alertImageView.image = [UIImage imageNamed:@"messageSendFail"];
    }
    return _alertImageView;
}

- (UILabel *)alertLabel {
    if (_alertLabel == nil) {
        _alertLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_alertImageView.frame) + kCDHorizontalLittleSpacing, 0, self.frame.size.width - CGRectGetMaxX(_alertImageView.frame) - kCDHorizontalSpacing - kCDHorizontalLittleSpacing, kCDIMClientStatusViewHight)];
        _alertLabel.font = [UIFont systemFontOfSize:15.0];
        _alertLabel.textColor = [UIColor grayColor];
        _alertLabel.text = @"会话断开，请检查网络";
    }
    return _alertLabel;
}

- (CDNotify *)notify {
    if (_notify == nil) {
        _notify = [CDNotify sharedInstance];
    }
    return _notify;
}

#pragma mark

- (void)observeIMClientUpdate {
    [self.notify addSessionObserver:self selector:@selector(imClientStatusUpdate:)];
    [self imClientStatusUpdate:nil];
}

+ (BOOL)connected {
    CDReachability *reachability = [CDReachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

- (void)imClientStatusUpdate:(id)sender {
    if ([[CDIM sharedInstance] isOpened] == NO) {
        if ([_delegate respondsToSelector:@selector(onIMClientPauseWithStateView:)])
            [_delegate onIMClientPauseWithStateView:self];
    }
    else {
        if ([_delegate respondsToSelector:@selector(onIMClientOpenWithStateView:)]) {
            [_delegate onIMClientOpenWithStateView:self];
        }
    }
}

- (void)dealloc {
    [self.notify removeSessionObserver:self];
}

@end

//
//  CDNetworkStateView.h
//  LeanChat
//
//  Created by lzw on 15/1/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDNotify.h"

static CGFloat kCDIMClientStatusViewHight = 44;

@class CDIMClientStatusView;


@protocol CDIMClientStatusViewDelegate <NSObject>

@optional

- (void)onIMClientPauseWithStatusView:(CDIMClientStatusView *)view;

- (void)onIMClientOpenWithStatusView:(CDIMClientStatusView *)view;

@end

@interface CDIMClientStatusView : UIView

@property (nonatomic) UITableView *tableView;

@property id <CDIMClientStatusViewDelegate> delegate;

- (void)observeIMClientUpdate;

@end

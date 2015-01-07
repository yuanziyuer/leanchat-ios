//
//  CDNetworkStateView.h
//  LeanChat
//
//  Created by lzw on 15/1/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDCommon.h"
#import "CDSessionManager.h"

static CGFloat kCDSessionStateViewHight=44;

@class CDSessionStateView;


@protocol CDSessionStateProtocal <NSObject>

@optional

-(void)onSessionBrokenWithStateView:(CDSessionStateView*)view;

-(void)onSessionFineWithStateView:(CDSessionStateView*)view;

@end

@interface CDSessionStateView : UIView

@property(nonatomic)UITableView* tableView;

@property id<CDSessionStateProtocal> delegate;

-(instancetype)initWithWidth:(CGFloat)width;

-(void)observeSessionUpdate;

@end

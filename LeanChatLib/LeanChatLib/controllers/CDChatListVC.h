//
//  CDChatListController.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/25/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "MCBaseTC.h"
#import "AVIMConversation+Custom.h"

@class CDChatListVC;

@protocol CDChatListVCDelegate <NSObject>

-(void)setBadgeWithTotalUnreadCount:(NSInteger)totalUnreadCount;

-(void)viewController:(UIViewController*)viewController didSelectConv:(AVIMConversation*)conv;

@end

@interface CDChatListVC : MCBaseTC

@property (nonatomic,strong) id<CDChatListVCDelegate> chatListDelegate;

@end

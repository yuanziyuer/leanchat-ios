//
//  CDChatRoomController.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDCommon.h"
#import "CDSessionManager.h"
#import "CDChatGroup.h"
#import "FMDB.h"
#import "XHMessageTableViewController.h"
#import "CDSessionStateView.h"


@class CDChatRoomVC;


@interface CDChatRoomVC : XHMessageTableViewController

-(instancetype)initWithConv:(AVIMConversation*)conv;

+(void)initWithUserId:(NSString*)userId fromVC:(UIViewController*)vc;

@end

//
//  CDChatRoomController.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDCommon.h"
#import "FMDB.h"
#import "XHMessageTableViewController.h"
#import "CDSessionStateView.h"


@class CDChatRoomVC;


@interface CDChatRoomVC : XHMessageTableViewController

+(void)goWithUserId:(NSString*)userId fromVC:(UIViewController*)vc;

+(void)goWithConv:(AVIMConversation*)conv fromVC:(UIViewController*)vc;

+(void)goWithConv:(AVIMConversation*)conv fromNav:(UINavigationController*)nav;

@end

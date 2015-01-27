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


@class CDChatRoomController;


@interface CDChatRoomController : XHMessageTableViewController

@property (nonatomic,strong) AVIMConversation* conversation;

//@property (nonatomic, strong) AVUser *chatUser;

//@property (nonatomic) CDMsgRoomType type;

//@property (nonatomic,strong) CDChatGroup* chatGroup;

//@property (nonatomic, strong) AVGroup *group;

-(instancetype)initWithConversation:(AVIMConversation*)conversation;

+(void)chatWithUserId:(NSString*)userId fromVC:(UIViewController*)controller;

@end

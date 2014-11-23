//
//  CDChatRoomController.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDCommon.h"
#import "CDSessionManager.h"
#import "ChatGroup.h"

#import "XHMessageTableViewController.h"

@class CDChatRoomController;


@interface CDChatRoomController : XHMessageTableViewController

@property (nonatomic, strong) AVUser *chatUser;
@property (nonatomic) CDMsgRoomType type;
@property (nonatomic,strong) ChatGroup* chatGroup;

@property (nonatomic, strong) AVGroup *group;

@end

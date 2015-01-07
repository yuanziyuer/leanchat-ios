//
//  CDChatListController.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/25/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDBaseTableController.h"
#import "CDSessionStateView.h"
#import "CDGroupService.h"
#import "CDCommon.h"
#import "SRRefreshView.h"

@interface CDChatListController : UIViewController<UITableViewDataSource,UITableViewDelegate,CDSessionStateProtocal,SRRefreshDelegate>

@property (nonatomic) CDSessionStateView* networkStateView;

@end

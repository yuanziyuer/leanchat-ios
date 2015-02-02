//
//  CDChatListController.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/25/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDBaseTableVC.h"
#import "CDSessionStateView.h"
#import "CDGroupService.h"
#import "CDCommon.h"
#import "SRRefreshView.h"

@interface CDChatListVC : UIViewController<UITableViewDataSource,UITableViewDelegate,CDSessionStateProtocal>

@property (nonatomic) CDSessionStateView* networkStateView;

@end

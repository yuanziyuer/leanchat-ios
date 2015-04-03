//
//  CDChatListController.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/25/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDBaseTableVC.h"
#import "CDCommon.h"

@interface CDChatListVC : UIViewController<UITableViewDataSource,UITableViewDelegate,CDSessionStateProtocal>

@property (nonatomic) CDSessionStateView* networkStateView;

@end

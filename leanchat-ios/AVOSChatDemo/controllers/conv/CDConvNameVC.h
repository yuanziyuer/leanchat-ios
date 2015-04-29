//
//  CDConvNameVC.h
//  LeanChat
//
//  Created by lzw on 15/2/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDCommon.h"
#import "CDConvDetailVC.h"

@interface CDConvNameVC : UITableViewController

@property CDConvDetailVC *detailVC;

@property AVIMConversation *conv;

@end

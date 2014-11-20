//
//  CDGroupDetailController.h
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDCommon.h"
#import "ChatGroup.h"

@interface CDGroupDetailController : UICollectionViewController<UIGestureRecognizerDelegate,UIAlertViewDelegate>

@property ChatGroup* chatGroup;

@end

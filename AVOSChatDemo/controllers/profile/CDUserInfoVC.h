//
//  CDUserInfoController.h
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDCommon.h"

@interface CDUserInfoVC : UIViewController

@property (weak,nonatomic) AVUser *user;

-(instancetype)initWithUser:(AVUser*)user;

@end

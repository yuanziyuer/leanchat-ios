//
//  CDBaseController.h
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/24/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDUtils.h"
#import "CDCommon.h"

@interface CDBaseVC : UIViewController

-(void)showProgress;

-(void)hideProgress;

-(void)showHUDText:(NSString*)text;

@end

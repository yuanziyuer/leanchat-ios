//
//  CDNotification.h
//  LeanChat
//
//  Created by lzw on 15/2/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"

@interface CDNotify : NSObject

+(instancetype)sharedInstance;

-(void)addConvObserver:(id)target selector:(SEL)selector;

-(void)removeConvObserver:(id)target;

-(void)postConvNotify;

@end

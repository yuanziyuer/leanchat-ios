//
//  CDMsg.h
//  LeanChat
//
//  Created by lzw on 15/2/3.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"

@interface CDMsg : NSObject

@property int localId;

@property AVIMTypedMessage* innerMsg;

@end

//
//  CDIMUtils.h
//  LeanChat
//
//  Created by lzw on 15/1/26.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"

@interface CDIMUtils : NSObject

+(NSString*)getOtherIdOfConv:(AVIMConversation*)conv;

+(NSString*)getMsgDesc:(AVIMTypedMessage*)msg;

@end

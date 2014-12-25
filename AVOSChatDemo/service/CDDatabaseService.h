//
//  CDDatabaseService.h
//  LeanChat
//
//  Created by lzw on 14/12/3.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDMsg.h"

@interface CDDatabaseService : NSObject

+(void)markHaveReadOfMsgs:(NSArray*)msgs;

+(CDMsg*)insertMsgToDB:(CDMsg*)msg;

+(void)findConversationsWithCallback:(AVArrayResultBlock)callback;

+(NSArray*)getMsgsWithConvid:(NSString*)convid maxTimestamp:(int64_t)timestamp limit:(int)limit;

+(int64_t)getMaxTimetstamp;

+(void)upgradeToAddField;

+(void)updateMsgWithId:(NSString*)objectId status:(CDMsgStatus)status;

+(void)updateMsgWithId:(NSString*)objectId content:(NSString*)content;

@end

//
//  CDDatabaseService.h
//  LeanChat
//
//  Created by lzw on 14/12/3.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDMsg.h"
#import "CDUtils.h"
#import "FMDB.h"

@interface CDDatabaseService : NSObject


+(void)markHaveReadWithConvid:(NSString*)convid;

+(void)insertMsgToDB:(CDMsg*)msg;

+(void)findConversationsWithCallback:(AVArrayResultBlock)callback;

+(NSArray*)getMsgsWithConvid:(NSString*)convid maxTimestamp:(int64_t)timestamp limit:(int)limit db:(FMDatabase*)db;


+(int64_t)getMaxTimetstampWithDB:(FMDatabase*)db;

+(void)upgradeToAddField;

+(void)updateMsgWithId:(NSString*)objectId status:(CDMsgStatus)status timestamp:(int64_t)timestamp;

+(void)updateMsgWithId:(NSString*)objectId status:(CDMsgStatus)status;

+(void)updateMsgWithId:(NSString*)objectId content:(NSString*)content;

+(FMDatabaseQueue*) databaseQueue;

@end

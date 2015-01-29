//
//  CDStorage.h
//  LeanChat
//
//  Created by lzw on 15/1/29.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCommon.h"
#import "FMDB.h"

@interface CDStorage : NSObject

+(instancetype)sharedInstance;

-(void)setupWithUserId:(NSString*)userId;

-(NSArray*)getMsgsWithConvid:(NSString*)convid maxTime:(int64_t)time limit:(int)limit db:(FMDatabase*)db;

-(void)insertMsg:(AVIMTypedMessage*)msg;

-(FMDatabaseQueue*)getDBQueue;

@end

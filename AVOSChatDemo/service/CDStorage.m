//
//  CDStorage.m
//  LeanChat
//
//  Created by lzw on 15/1/29.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDStorage.h"
#import "CDUtils.h"
#import "CDModels.h"

#define MSG_TABLE_SQL @"create table if not exists msgs(id integer primary key,msg_id varchar(63) unique not null,convid varchar(63) not null,object blob not null,time varchar(63) not null)"

#define FIELD_ID @"id"
#define FIELD_CONVID @"convid"
#define FIELD_OBJECT @"object"
#define FIELD_TIME @"time"
#define FIELD_MSG_ID @"msg_id"

static CDStorage* _storage;

@interface CDStorage(){
    
}

@property FMDatabaseQueue* dbQueue;

@end

@implementation CDStorage

+(instancetype)sharedInstance{
    if(_storage==nil){
        _storage=[[CDStorage alloc] init];
    }
    return _storage;
}

- (NSString *)dbPathWithUserId:(NSString*)userId {
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [libPath stringByAppendingPathComponent:[NSString stringWithFormat:@"chat_%@",userId]];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(void)setupWithUserId:(NSString*)userId{
    _dbQueue=[FMDatabaseQueue databaseQueueWithPath:[self dbPathWithUserId:userId]];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:MSG_TABLE_SQL];
    }];
}

-(NSArray*)getMsgsWithConvid:(NSString*)convid maxTime:(int64_t)time limit:(int)limit db:(FMDatabase*)db{
    NSString* timeStr=[CDUtils strOfInt64:time];
    FMResultSet* rs=[db executeQuery:@"select * from msgs where convid=? and time<? order by time desc limit ?" withArgumentsInArray:@[convid,timeStr,@(limit)]];
    NSMutableArray* msgs=[self getMsgsByResultSet:rs];
    return [CDUtils reverseArray:msgs];
}

-(NSMutableArray*)getMsgsByResultSet:(FMResultSet*)rs{
    NSMutableArray *result = [NSMutableArray array];
    while ([rs next]) {
        AVIMTypedMessage *msg=[self getMsgByResultSet:rs];
        [result addObject:msg];
    }
    [rs close];
    return result;
}

-(AVIMTypedMessage* )getMsgByResultSet:(FMResultSet*)rs{
    NSData* data=[rs objectForColumnName:FIELD_OBJECT];
    AVIMTypedMessage* msg=[NSKeyedUnarchiver unarchiveObjectWithData:data];
    return msg;
}

-(void)insertMsg:(AVIMTypedMessage*)msg{
    [_dbQueue inDatabase:^(FMDatabase *db) {
        NSData* data=[NSKeyedArchiver archivedDataWithRootObject:msg];
        NSDictionary* dict=@{FIELD_MSG_ID:msg.messageId,FIELD_CONVID:msg.conversationId,FIELD_OBJECT:data,FIELD_TIME:[CDUtils strOfInt64:msg.sendTimestamp]};
        [db executeUpdate:@"insert into msgs (msg_id,convid,object,time) values(:msg_id,:convid,:object,:time)" withParameterDictionary:dict];
    }];
}

-(FMDatabaseQueue*)getDBQueue{
    return _dbQueue;
}

@end

//
//  CDDatabaseService.m
//  LeanChat
//
//  Created by lzw on 14/12/3.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDDatabaseService.h"
#import "FMDB.h"
#import "CDUtils.h"
#import "CDCacheService.h"
#import "CDChatRoom.h"

static FMDatabase *database;

static NSString *messagesTableSQL=@"create table if not exists messages (id integer primary key, objectId varchar(63) unique not null,ownerId varchar(255) not null,fromPeerId varchar(255) not null, convid varchar(255) not null,toPeerId varchar(255),content varchar(1023) ,status integer,type integer,roomType integer,readStatus integer default 1,timestamp varchar(63) not null)";

@implementation CDDatabaseService

+(void)initialize{
    [super initialize];
    database = [FMDatabase databaseWithPath:[self databasePath]];
    [database open];    
    [self createTable];
}

+(void)createTable{
    if (![database tableExists:@"messages"]) {
        [database executeUpdate:messagesTableSQL];
    }
}

+ (NSString *)databasePath {
    static NSString *databasePath = nil;
    if (!databasePath) {
        NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        databasePath = [cacheDirectory stringByAppendingPathComponent:@"chat.db"];
    }
    return databasePath;
}

+(void)upgradeToAddField{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [database executeStatements:@"drop table if exists messages"];
    [self createTable];
}

+(CDMsg* )getMsgByResultSet:(FMResultSet*)rs{
    NSString *fromid = [rs stringForColumn:FROM_PEER_ID];
    NSString *toid = [rs stringForColumn:TO_PEER_ID];
    NSString *convid=[rs stringForColumn:CONV_ID];
    NSString *objectId=[rs stringForColumn:OBJECT_ID];
    NSString* timestampText = [rs stringForColumn:TIMESTAMP];
    int64_t timestamp=[timestampText longLongValue];
    NSString* content=[rs stringForColumn:CONTENT];
    CDMsgRoomType roomType=[rs intForColumn:ROOM_TYPE];
    CDMsgType type=[rs intForColumn:TYPE];
    CDMsgStatus status=[rs intForColumn:STATUS];
    CDMsgReadStaus readStatus=[rs intForColumn:READ_STATUS];
    
    CDMsg* msg=[[CDMsg alloc] init];
    msg.fromPeerId=fromid;
    msg.objectId=objectId;
    msg.toPeerId=toid;
    msg.timestamp=timestamp;
    msg.content=content;
    msg.type=type;
    msg.status=status;
    msg.roomType=roomType;
    msg.convid=convid;
    msg.readStatus=readStatus;
    return msg;
}

+(NSMutableArray*)getMsgsByResultSet:(FMResultSet*)rs{
    NSMutableArray *result = [NSMutableArray array];
    while ([rs next]) {
        CDMsg *msg=[self getMsgByResultSet :rs];
        [result addObject:msg];
    }
    [rs close];
    return result;
}

+(void)findConversationsWithCallback:(AVArrayResultBlock)callback{
    [CDUtils runInGlobalQueue:^{
        AVUser* user=[AVUser currentUser];
        FMResultSet *rs = [database executeQuery:@"select * from messages where ownerId=? group by convid order by timestamp desc" withArgumentsInArray:@[user.objectId]];
        NSArray *msgs=[self getMsgsByResultSet:rs];
        [CDCacheService cacheMsgs:msgs withCallback:^(NSArray *objects, NSError *error) {
            if(error){
                [CDUtils runInMainQueue:^{
                    callback(nil,error);
                }];
            }else{
                NSMutableArray *chatRooms=[[NSMutableArray alloc] init];
                for(CDMsg* msg in msgs){
                    CDChatRoom* chatRoom=[[CDChatRoom alloc] init];
                    chatRoom.roomType=msg.roomType;
                    FMResultSet * countResult=[database executeQuery:@"select count(*) from messages where convid=? and readStatus=?" withArgumentsInArray:@[msg.convid,@(CDMsgReadStatusUnread)]];
                    NSInteger count=0;
                    if([countResult next]){
                        count=[countResult intForColumnIndex:0];
                    }
                    [countResult close];
                    chatRoom.unreadCount=count;
                    
                    NSString* otherId=[msg getOtherId];
                    if(msg.roomType==CDMsgRoomTypeSingle){
                        chatRoom.chatUser=[CDCacheService lookupUser:otherId];;
                    }else{
                        chatRoom.chatGroup=[CDCacheService lookupChatGroupById:otherId];
                    }
                    chatRoom.latestMsg=msg;
                    [chatRooms addObject:chatRoom];
                }
                [CDUtils runInMainQueue:^{
                    callback(chatRooms,error);
                }];
            }
        }];
    }];
}

+(CDMsg*)insertMsgToDB:(CDMsg*)msg{
    NSDictionary *dict=[msg toDatabaseDict];
    [database executeUpdate:@"insert into messages (objectId,ownerId , fromPeerId, toPeerId, content,convid,status,type,roomType,readStatus,timestamp) values (:objectId,:ownerId,:fromPeerId,:toPeerId,:content,:convid,:status,:type,:roomType,:readStatus,:timestamp)" withParameterDictionary:dict];
    return msg;
}

+ (NSMutableArray*)getMsgsForConvid:(NSString*)convid{
    FMResultSet * rs=[database executeQuery:@"select * from messages where convid=? order by timestamp" withArgumentsInArray:@[convid]];
    return [self getMsgsByResultSet:rs];
}

+(NSArray*)getMsgsWithConvid:(NSString*)convid maxTimestamp:(int64_t)timestamp limit:(int)limit{
    NSString* timestampStr=[[NSNumber numberWithLongLong:timestamp] stringValue];
    FMResultSet* rs=[database executeQuery:@"select * from messages where convid=? and timestamp<? order by timestamp desc limit ?" withArgumentsInArray:@[convid,timestampStr,@(limit)]];
    NSMutableArray* msgs=[self getMsgsByResultSet:rs];
    return [CDUtils reverseArray:msgs];
}

+(int64_t)getMaxTimestampFromDB{
    FMResultSet* rs=[database executeQuery:@"select * from messages order by timestamp desc limit 1"];
    NSArray* array=[self getMsgsByResultSet:rs];
    if([array count]>0){
        CDMsg* msg=[array firstObject];
        return msg.timestamp;
    }else{
        return -1;
    }
}

+(int64_t)getMaxTimetstamp{
    int64_t timestamp=[self getMaxTimestampFromDB];
    if(timestamp!=-1){
        return timestamp+1;
    }else{
        NSDate* now=[NSDate date];
        int sec=[now timeIntervalSince1970]+10;
        return  (int64_t)sec*1000;
    }
}

+(void)markHaveReadOfMsgs:(NSArray*)msgs{
    BOOL hasUnread=NO;
    for(CDMsg* msg in msgs){
        if(msg.readStatus==CDMsgReadStatusUnread){
            hasUnread=YES;
            break;
        }
    }
    if(!hasUnread){
        return;
    }
    [database beginTransaction];
    for(CDMsg* msg in msgs){
        if(msg.readStatus==CDMsgReadStatusUnread){
            msg.readStatus=CDMsgReadStatusHaveRead;
            [database executeUpdate:@"update messages set readStatus=? where objectId=?" withArgumentsInArray:@[@(CDMsgReadStatusHaveRead),msg.objectId]];
        }
    }
    [database commit];
}

+(void)updateMsgWithId:(NSString*)objectId status:(CDMsgStatus)status timestamp:(int64_t)timestamp{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [self updateMsgWithId:objectId status:status];
    NSString* timestampText=[NSString stringWithFormat:@"%lld",timestamp];
    [database executeUpdate:@"update messages set timestamp=? where objectId=?" withArgumentsInArray:@[timestampText,objectId]];
}

+(void)updateMsgWithId:(NSString*)objectId status:(CDMsgStatus)status{
    [database executeUpdate:@"update messages set status=? where objectId=?" withArgumentsInArray:@[@(status),objectId]];
}

@end

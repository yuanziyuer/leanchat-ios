//
//  CDStorage.m
//  LeanChat
//
//  Created by lzw on 15/1/29.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDStorage.h"
#import "CDMacros.h"

#define ROOMS_TABLE_SQL @"CREATE TABLE IF NOT EXISTS `rooms` (`id` INTEGER PRIMARY KEY AUTOINCREMENT,`convid` VARCHAR(63) UNIQUE NOT NULL,`unread_count` INTEGER DEFAULT 0)"

#define FIELD_ID @"id"
#define FIELD_CONVID @"convid"
#define FIELD_UNREAD_COUNT @"unread_count"

static CDStorage *_storage;

@interface CDStorage () {
}

@property FMDatabaseQueue *dbQueue;

@end

@implementation CDStorage

+ (instancetype)sharedInstance {
    if (_storage == nil) {
        _storage = [[CDStorage alloc] init];
    }
    return _storage;
}

- (void)close {
    _storage = nil;
}

- (NSString *)dbPathWithUserId:(NSString *)userId {
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [libPath stringByAppendingPathComponent:[NSString stringWithFormat:@"chat_%@", userId]];
}

- (void)setupWithUserId:(NSString *)userId {
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self dbPathWithUserId:userId]];
    [_dbQueue inDatabase: ^(FMDatabase *db) {
        [db executeUpdate:ROOMS_TABLE_SQL];
    }];
}

#pragma mark - rooms table

- (CDRoom *)getRoomByResultSet:(FMResultSet *)rs {
    CDRoom *room = [[CDRoom alloc] init];
    room.convid = [rs stringForColumn:FIELD_CONVID];
    room.unreadCount = [rs intForColumn:FIELD_UNREAD_COUNT];
    return room;
}

- (NSArray *)getRooms {
    NSMutableArray *rooms = [NSMutableArray array];
    [_dbQueue inDatabase: ^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM rooms LEFT JOIN (SELECT msgs.object,MAX(time) as time ,msgs.convid as msg_convid FROM msgs GROUP BY msgs.convid) ON rooms.convid=msg_convid ORDER BY time DESC"];
        while ([rs next]) {
            [rooms addObject:[self getRoomByResultSet:rs]];
        }
        [rs close];
    }];
    return rooms;
}

- (NSInteger)countUnread {
    __block NSInteger unreadCount = 0;
    [_dbQueue inDatabase: ^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT SUM(rooms.unread_count) FROM rooms"];
        if ([rs next]) {
            unreadCount = [rs intForColumnIndex:0];
        }
    }];
    return unreadCount;
}

- (void)insertRoomWithConvid:(NSString *)convid {
    [_dbQueue inDatabase: ^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM rooms WHERE convid=?", convid];
        if ([rs next] == NO) {
            [db executeUpdate:@"INSERT INTO rooms (convid) VALUES(?) ", convid];
        }
        [rs close];
    }];
}

- (void)deleteRoomByConvid:(NSString *)convid {
    [_dbQueue inDatabase: ^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM rooms WHERE convid=?" withArgumentsInArray:@[convid]];
    }];
}

- (void)incrementUnreadWithConvid:(NSString *)convid {
    [_dbQueue inDatabase: ^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE rooms SET unread_count=unread_count+1 WHERE convid=?" withArgumentsInArray:@[convid]];
    }];
}

- (void)clearUnreadWithConvid:(NSString *)convid {
    [_dbQueue inDatabase: ^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE rooms SET unread_count=0 WHERE convid=?" withArgumentsInArray:@[convid]];
    }];
}

@end

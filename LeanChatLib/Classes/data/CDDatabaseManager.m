//
//  CDDatabaseManager.m
//  LeanChatLib
//
//  Created by lzw on 15/7/13.
//  Copyright (c) 2015年 lzwjava@LeanCloud QQ: 651142978. All rights reserved.
//

#import "CDDatabaseManager.h"
#import <FMDB/FMDB.h>
#import "AVIMConversation+Custom.h"
#import "CDMacros.h"

#define kCDConversationTableName @"conversations"

#define kCDConversationTableKeyId @"id"
#define kCDConversationTableKeyData @"data"
#define kCDConversationTableKeyUnreadCount @"unreadCount"
#define kCDConversationTableKeyMentioned @"mentioned"

#define kCDConversatoinTableCreateSQL                                       \
    @"CREATE TABLE IF NOT EXISTS " kCDConversationTableName @" ("           \
        kCDConversationTableKeyId           @" VARCHAR(63) PRIMARY KEY, "   \
        kCDConversationTableKeyData         @" BLOB NOT NULL, "             \
        kCDConversationTableKeyUnreadCount  @" INTEGER DEFAULT 0, "         \
        kCDConversationTableKeyMentioned    @" BOOL DEFAULT FALSE "         \
    @")"

#define kCDConversationTableInsertSQL                           \
    @"INSERT OR IGNORE INTO " kCDConversationTableName @" ("    \
        kCDConversationTableKeyId           @", "               \
        kCDConversationTableKeyData         @", "               \
        kCDConversationTableKeyUnreadCount  @", "               \
        kCDConversationTableKeyMentioned                        \
    @") VALUES(?, ?, ?, ?)"

#define kCDConversationTableWhereClause                         \
    @"WHERE " kCDConversationTableKeyId @" = ?"

#define kCDConversationTableDeleteSQL                           \
    @"DELETE FROM " kCDConversationTableName  @" "              \
    kCDConversationTableWhereClause

#define kCDConversationTableIncreaseUnreadCountSQL              \
    @"UPDATE " kCDConversationTableName        @" "             \
    @"SET " kCDConversationTableKeyUnreadCount @" = "           \
            kCDConversationTableKeyUnreadCount @"+ 1 "          \
    kCDConversationTableWhereClause

#define kCDConversationTableUpdateUnreadCountSQL                \
    @"UPDATE " kCDConversationTableName         @" "            \
    @"SET  " kCDConversationTableKeyUnreadCount @" = ? "        \
    kCDConversationTableWhereClause

#define kCDConversationTableUpdateMentionedSQL                  \
    @"UPDATE " kCDConversationTableName  @" "                   \
    @"SET  " kCDConversationTableKeyMentioned @" = ? "         \
    kCDConversationTableWhereClause

#define kCDConversationTableSelectSQL                           \
    @"SELECT * FROM " kCDConversationTableName                  \

@interface CDDatabaseManager ()

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end

@implementation CDDatabaseManager

+ (CDDatabaseManager *)manager {
    static CDDatabaseManager *manager;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        manager = [[CDDatabaseManager alloc] init];
    });
    return manager;
}

- (void)setupDatabaseWithUserId:(NSString *)userId {
    if (self.databaseQueue) {
        DLog(@"database queue not nil !!!!");
    }
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:[self databasePathWithUserId:userId]];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:kCDConversatoinTableCreateSQL];
    }];
}

#pragma mark - conversations local data

- (NSString *)databasePathWithUserId:(NSString *)userId{
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [libPath stringByAppendingPathComponent:[NSString stringWithFormat:@"com.leancloud.leanchatlib.%@.db3", userId]];
}

- (void)updateUnreadCountToZeroWithConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:kCDConversationTableUpdateUnreadCountSQL  withArgumentsInArray:@[@0 , conversation.conversationId]];
    }];
}

- (void)deleteConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:kCDConversationTableDeleteSQL withArgumentsInArray:@[conversation.conversationId]];
    }];
}

- (void )createConversatioRecord:(AVIMConversation *)conversation {
    if (conversation.creator == nil) {
        return;
    }
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        AVIMKeyedConversation *keydConversation = [conversation keyedConversation];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keydConversation];
        [db executeUpdate:kCDConversationTableInsertSQL withArgumentsInArray:@[conversation.conversationId, data, @0, @(NO)]];
    }];
}

- (void)increaseUnreadCountWithConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:kCDConversationTableIncreaseUnreadCountSQL withArgumentsInArray:@[conversation.conversationId]];
    }];
}

- (void)updateConversation:(AVIMConversation *)conversation mentioned:(BOOL)mentioned {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:kCDConversationTableUpdateMentionedSQL withArgumentsInArray:@[kCDConversationTableKeyUnreadCount, @(mentioned), conversation.conversationId]];
    }];
}

- (AVIMConversation *)createConversationFromResultSet:(FMResultSet *)resultSet {
    NSData *data = [resultSet dataForColumn:kCDConversationTableKeyData];
    NSInteger unreadCount = [resultSet intForColumn:kCDConversationTableKeyUnreadCount];
    BOOL mentioned = [resultSet boolForColumn:kCDConversationTableKeyMentioned];
    
    AVIMKeyedConversation *keyedConversation = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    AVIMConversation *conversation = [[AVIMClient defaultClient] conversationWithKeyedConversation:keyedConversation];
    conversation.unreadCount = unreadCount;
    conversation.mentioned = mentioned;
    return conversation;
}

- (NSArray *)selectAllConversations {
    NSMutableArray *conversations = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * resultSet = [db executeQuery:kCDConversationTableSelectSQL withArgumentsInArray:@[]];
        while ([resultSet next]) {
            [conversations addObject:[self createConversationFromResultSet:resultSet]];
        }
        [resultSet close];
    }];
    return conversations;
}

@end

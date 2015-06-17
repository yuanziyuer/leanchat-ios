//
//  CDStorage.m
//  LeanChat
//
//  Created by lzw on 15/1/29.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDStorage.h"

static CDStorage *storageInstance;

@interface CDStorage ()

@property (nonatomic, strong) NSString *plistPath;

@property (nonatomic, strong) NSMutableArray *rooms;

@end

@implementation CDStorage

+ (instancetype)storage {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        storageInstance = [[CDStorage alloc] init];
    });
    return storageInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.rooms = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationGoBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)applicationGoBackground {
    [self saveData];
}

- (NSString *)plistPathWithUserId:(NSString *)userId{
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [libPath stringByAppendingPathComponent:[NSString stringWithFormat:@"chat_%@.plist", userId]];
}

- (void)saveData {
    if (self.plistPath) {
        [NSKeyedArchiver archiveRootObject:self.rooms toFile:self.plistPath];
    }
}

- (NSArray *)readFromPath:(NSString *)path {
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (exists) {
        return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    } else {
        return [NSArray array];
    }
}

- (void)setupWithUserId:(NSString *)userId {
    if (self.rooms.count > 0) {
        [self saveData];
    }
    self.plistPath = [self plistPathWithUserId:userId];
    NSLog(@"plistPath = %@", self.plistPath);
    self.rooms = [[self readFromPath:self.plistPath] mutableCopy];
    if (self.rooms == nil) {
        self.rooms = [NSMutableArray array];
    }
}

- (void)dealloc {
    [self saveData];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)close {
    [self saveData];
}

#pragma mark - rooms table

- (NSArray *)getRooms {
    return self.rooms;
}

- (NSInteger)countUnread {
    __block NSInteger unreadCount = 0;
    for (CDRoom *room in self.rooms) {
        unreadCount += room.unreadCount;
    }
    return unreadCount;
}

- (CDRoom *)findRoomWithConvid:(NSString *)convid {
    for (CDRoom *room in self.rooms) {
        if ([room.convid isEqualToString:convid]) {
            return room;
        }
    }
    return nil;
}

- (void)insertRoomWithConvid:(NSString *)convid {
    CDRoom *room = [self findRoomWithConvid:convid];
    if (room == nil) {
        CDRoom *room = [[CDRoom alloc] init];
        room.convid = convid;
        room.unreadCount = 0;
        [self.rooms addObject:room];
    }
}

- (void)deleteRoomByConvid:(NSString *)convid {
    CDRoom *room = [self findRoomWithConvid:convid];
    [self.rooms removeObject:room];
}

- (void)incrementUnreadWithConvid:(NSString *)convid {
    CDRoom *room = [self findRoomWithConvid:convid];
    if (room) {
        room.unreadCount ++;
    }
}

- (void)clearUnreadWithConvid:(NSString *)convid {
    CDRoom *room = [self findRoomWithConvid:convid];
    room.unreadCount = 0;
}

@end

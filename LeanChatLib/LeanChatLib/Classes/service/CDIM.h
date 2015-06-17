//
//  CDIMClient.h
//  LeanChat
//
//  Created by lzw on 15/1/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDAVOSHeaders.h"
#import "CDUserModel.h"
#import "AVIMConversation+Custom.h"

static NSString *const kCDNotificationMessageReceived = @"MessageReceived";
static NSString *const kCDNotificationMessageDelivered = @"MessageDelivered";
static NSString *const kCDNotificationConversationUpdated = @"ConversationUpdated";

@interface CDIM : NSObject

@property (nonatomic, strong) AVIMClient *imClient;
@property (nonatomic, strong, readonly) NSString *selfId;
@property (nonatomic, strong) id <CDUserModel> selfUser;
@property (nonatomic, assign) BOOL connect;

+ (instancetype)sharedInstance;

- (void)openWithClientId:(NSString *)clientId callback:(AVIMBooleanResultBlock)callback;
- (void)closeWithCallback:(AVBooleanResultBlock)callback;

- (void)fecthConvWithId:(NSString *)convid callback:(AVIMConversationResultBlock)callback;
- (void)fetchConvWithOtherId:(NSString *)otherId callback:(AVIMConversationResultBlock)callback;
- (void)fetchConvWithMembers:(NSArray *)members callback:(AVIMConversationResultBlock)callback;
- (void)fetchConvsWithConvids:(NSSet *)convids callback:(AVIMArrayResultBlock)callback;
- (void)findGroupedConvsWithBlock:(AVIMArrayResultBlock)block;

- (void)createConvWithMembers:(NSArray *)members type:(CDConvType)type callback:(AVIMConversationResultBlock)callback;
- (void)updateConv:(AVIMConversation *)conv name:(NSString *)name attrs:(NSDictionary *)attrs callback:(AVIMBooleanResultBlock)callback;

- (void)queryTypedMessagesWithConversation:(AVIMConversation *)conversation timestamp:(int64_t)timestamp limit:(NSInteger)limit block:(AVIMArrayResultBlock)block;

- (void)findRecentRoomsWithBlock:(AVArrayResultBlock)block;

- (NSString *)getPathByObjectId:(NSString *)objectId;
- (NSString *)tmpPath;
- (NSString *)uuid;

@end

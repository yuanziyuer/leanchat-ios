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

@interface CDIM : NSObject

@property AVIMClient* imClient;

@property (nonatomic,strong,readonly) NSString* selfId;

@property (nonatomic,strong) id<CDUserModel> selfUser;

+ (instancetype)sharedInstance;

-(void)openWithClientId:(NSString*)clientId callback:(AVIMBooleanResultBlock)callback;

- (void)closeWithCallback:(AVBooleanResultBlock)callback;

-(BOOL)isOpened;

-(void)fecthConvWithId:(NSString*)convid callback:(AVIMConversationResultBlock)callback;

- (void)fetchConvWithOtherId:(NSString *)otherId callback:(AVIMConversationResultBlock)callback;

-(void)fetchConvWithMembers:(NSArray*)members callback:(AVIMConversationResultBlock)callback;

-(void)fetchConvsWithConvids:(NSSet*)convids callback:(AVIMArrayResultBlock)callback;

-(void)createConvWithMembers:(NSArray*)members type:(CDConvType)type callback:(AVIMConversationResultBlock)callback;

- (void)updateConv:(AVIMConversation *)conv name:(NSString *)name attrs:(NSDictionary *)attrs callback:(AVIMBooleanResultBlock)callback ;

-(void)findGroupedConvsWithBlock:(AVIMArrayResultBlock)block;

-(NSArray*)queryMsgsWithConv:(AVIMConversation*)conv msgId:(NSString*)msgId maxTime:(int64_t)time limit:(int)limit error:(NSError**)theError;

-(void)cacheAndFillRooms:(NSMutableArray*)rooms callback:(AVBooleanResultBlock)callback;

#pragma mark - msg utils

-(NSString*)getMsgTitle:(AVIMTypedMessage*)msg;

#pragma mark - path utils

-(NSString*)getPathByObjectId:(NSString*)objectId;

-(NSString*)tmpPath;

#pragma mark - conv utils

-(NSString*)uuid;

@end

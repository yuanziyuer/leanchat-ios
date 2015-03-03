//
//  CDIMClient.m
//  LeanChat
//
//  Created by lzw on 15/1/21.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDIM.h"
#import "CDModels.h"
#import "CDService.h"

static CDIM*instance;

@interface CDIM()<AVIMClientDelegate,AVIMSignatureDataSource>{
    
}

@property CDStorage* storage;

@property CDNotify* notify;

@end

@implementation CDIM

#pragma mark - lifecycle

+ (instancetype)sharedInstance
{
    if(instance==nil){
        instance=[[CDIM alloc] init];
    }
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _imClient=[[AVIMClient alloc] init];
        _imClient.delegate=self;
        _storage=[CDStorage sharedInstance];
        _notify=[CDNotify sharedInstance];
        //_imClient.signatureDataSource=self;
    }
    return self;
}

-(BOOL)isOpened{
    return _imClient.status==AVIMClientStatusOpened;
}

-(void)open{
    [_imClient openWithClientId:[AVUser currentUser].objectId callback:^(BOOL succeeded, NSError *error) {
        [_notify postSessionNotify];
        [CDUtils logError:error callback:^{
            NSLog(@"im open succeed");
        }];
    }];
}

- (void)close {
    [_imClient closeWithCallback:nil];
    instance=nil;
}

#pragma mark - conversation

-(void)fecthConvWithId:(NSString*)convid callback:(AVIMConversationResultBlock)callback{
    AVIMConversationQuery* q=[_imClient conversationQuery];
    [q whereKey:@"objectId" equalTo:convid];
    [q findConversationsWithCallback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(nil,error);
        }else{
            callback([objects objectAtIndex:0],error);
        }
    }];;
}

- (void)fetchConvWithUserId:(NSString *)userId callback:(AVIMConversationResultBlock)callback {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject:_imClient.clientId];
    [array addObject:userId];
    AVIMConversationQuery* q=[_imClient conversationQuery];
    [q whereKey:@"m" sizeEqualTo:2];
    [q whereKey:@"m" containsAllObjectsInArray:array];
    [q findConversationsWithCallback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(nil,error);
        }else{
            AVIMConversationResultBlock WithConv=^(AVIMConversation* conv,NSError* error){
                if(error){
                }else{
                    callback(conv, nil);
                }
            };
            if (objects.count > 0) {
                AVIMConversation *conv = [objects objectAtIndex:0];
                WithConv(conv,nil);
            } else{
                [self createConvWithUserId:userId callback:WithConv];
            }
        }
    }];
}

-(void)createConvWithUserId:(NSString*)userId callback:(AVIMConversationResultBlock)callback{
    [_imClient createConversationWithName:nil clientIds:@[userId] attributes:@{CONV_TYPE:@(CDConvTypeSingle)} options:AVIMConversationOptionNone callback:callback];
}

-(void)createConvWithUserIds:(NSArray*)userIds callback:(AVIMConversationResultBlock)callback{
    NSString* name=[CDConvService nameOfUserIds:userIds];
    [_imClient createConversationWithName:name clientIds:userIds attributes:@{CONV_TYPE:@(CDConvTypeGroup)} options:AVIMConversationOptionNone callback:callback];
}

-(void)findGroupedConvsWithBlock:(AVIMArrayResultBlock)block{
    AVUser* user=[AVUser currentUser];
    AVIMConversationQuery* q=[_imClient conversationQuery];
    [q whereKey:@"attr.type" equalTo:@(CDConvTypeGroup)];
    [q whereKey:@"m" containedIn:@[user.objectId]];
    [q findConversationsWithCallback:block];
}

- (void)updateConv:(AVIMConversation *)conv name:(NSString *)name attrs:(NSDictionary *)attrs callback:(AVIMBooleanResultBlock)callback {
    NSMutableDictionary* dict=[NSMutableDictionary dictionary];
    if(name){
        [dict setObject:name forKey:@"name"];
    }
    if(attrs){
        [dict setObject:attrs forKey:@"attrs"];
    }
    [conv update:dict callback:callback];
}

-(void)fetchConvsWithIds:(NSSet*)convids callback:(AVIMArrayResultBlock)callback{
    if(convids.count>0){
        AVIMConversationQuery* q=[_imClient conversationQuery];
        [q whereKey:@"objectId" containedIn:[convids allObjects]];
        [q findConversationsWithCallback:callback];
    }else{
        callback([NSMutableArray array],nil);
    }
}

#pragma mark - send or receive message

-(void)receiveMsg:(AVIMTypedMessage*)msg conv:(AVIMConversation*)conv{
    [_storage insertRoomWithConvid:conv.conversationId];
    [_storage insertMsg:msg];
    [_storage incrementUnreadWithConvid:conv.conversationId];
    [_notify postMsgNotify:msg];
}

#pragma mark - AVIMClientDelegate

- (void)imClientPaused:(AVIMClient *)imClient{
    DLog();
    [_notify postSessionNotify];
}

- (void)imClientResuming:(AVIMClient *)imClient{
    DLog();
    [_notify postSessionNotify];
}

- (void)imClientResumed:(AVIMClient *)imClient{
    DLog();
    [_notify postSessionNotify];
}

#pragma mark - AVIMMessageDelegate

- (void)conversation:(AVIMConversation *)conversation didReceiveCommonMessage:(AVIMMessage *)message{
    DLog();
}

- (void)conversation:(AVIMConversation *)conversation didReceiveTypedMessage:(AVIMTypedMessage *)message{
    DLog();
    if(message.messageId){
        [self receiveMsg:message conv:conversation];
    }
}

- (void)conversation:(AVIMConversation *)conversation messageDelivered:(AVIMMessage *)message{
    if(message!=nil){
        [_storage updateStatus:AVIMMessageStatusDelivered byMsgId:message.messageId];
        [_notify postMsgNotify:message];
    }
    DLog();
}

- (void)conversation:(AVIMConversation *)conversation membersAdded:(NSArray *)clientIds byClientId:(NSString *)clientId{
    DLog();
}

- (void)conversation:(AVIMConversation *)conversation membersRemoved:(NSArray *)clientIds byClientId:(NSString *)clientId{
    DLog();
}

- (void)conversation:(AVIMConversation *)conversation invitedByClientId:(NSString *)clientId{
    DLog();
}

- (void)conversation:(AVIMConversation *)conversation kickedByClientId:(NSString *)clientId{
    DLog();
}

@end

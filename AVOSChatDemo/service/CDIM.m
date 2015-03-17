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
/* 取消下面的注释，将对 im的 open ，start(create conv),kick,invite 操作签名，更安全
   可以从你的服务器获得签名，这里从云代码获取，需要部署云代码，https://github.com/leancloud/leanchat-cloudcode
*/
        //_imClient.signatureDataSource=self;
        _storage=[CDStorage sharedInstance];
        _notify=[CDNotify sharedInstance];
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
    [q whereKey:CONV_ATTR_TYPE_KEY equalTo:@(CDConvTypeSingle)];
    [q whereKey:CONV_MEMBERS_KEY containsAllObjectsInArray:array];
    [q findConversationsWithCallback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(nil,error);
        }else{
            if (objects.count > 0) {
                AVIMConversation *conv = [objects objectAtIndex:0];
                callback(conv,nil);
            } else{
                [self createConvWithUserId:userId callback:callback];
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

#pragma mark - query msgs

-(NSArray*)queryMsgsWithConv:(AVIMConversation*)conv msgId:(NSString*)msgId maxTime:(int64_t)time limit:(int)limit error:(NSError**)theError{
    dispatch_semaphore_t sema=dispatch_semaphore_create(0);
    __block NSArray* result;
    __block NSError* blockError=nil;
    [conv queryHistoricalMessagesBeforeId:msgId timestamp:time limit:limit callback:^(NSArray *objects, NSError *error) {
        result=objects;
        blockError=error;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    *theError=blockError;
    if(blockError==nil){
    }
    return result;
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

-(AVIMSignature*)getAVSignatureWithParams:(NSDictionary*) fields peerIds:(NSArray*)peerIds{
    AVIMSignature* avSignature=[[AVIMSignature alloc] init];
    NSNumber* timestampNum=[fields objectForKey:@"timestamp"];
    long timestamp=[timestampNum longValue];
    NSString* nonce=[fields objectForKey:@"nonce"];
    NSString* signature=[fields objectForKey:@"signature"];

    [avSignature setTimestamp:timestamp];
    [avSignature setNonce:nonce];
    [avSignature setSignature:signature];;
    return avSignature;
}

- (AVIMSignature *)signatureWithClientId:(NSString *)clientId
                          conversationId:(NSString *)conversationId
                                  action:(NSString *)action
                       actionOnClientIds:(NSArray *)clientIds{
    if([action isEqualToString:@"open"] || [action isEqualToString:@"start"]){
        action=nil;
    }
    if([action isEqualToString:@"remove"]){
        action=@"kick";
    }
    if([action isEqualToString:@"add"]){
        action=@"invite";
    }
    NSDictionary* dict=[CDCloudService convSignWithSelfId:clientId convid:conversationId targetIds:clientIds action:action];
    if(dict!=nil){
        return [self getAVSignatureWithParams:dict peerIds:clientIds];
    }else{
        return nil;
    }
}

@end

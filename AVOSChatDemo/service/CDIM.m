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
static BOOL initialized;

@interface CDIM()<AVIMClientDelegate,AVIMSignatureDataSource>{
    
}

@property CDStorage* storage;

@property CDNotify* notify;

@end

@implementation CDIM

#pragma mark - lifecycle

+ (instancetype)sharedInstance
{
    static dispatch_once_t once_token=0;
    dispatch_once(&once_token, ^{
        instance=[[CDIM alloc] init];
    });
    if(!initialized){
        initialized=YES;
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
        [CDUtils logError:error callback:^{
            NSLog(@"im open succeed");
        }];
    }];
}

- (void)close {
    [_imClient closeWithCallback:nil];
    initialized = NO;
}

#pragma mark - conversation

-(void)fecthConvWithId:(NSString*)convid callback:(AVIMConversationResultBlock)callback{
    [_imClient queryConversationById:convid callback:callback];
}

- (void)fetchConvWithUserId:(NSString *)userId callback:(AVIMConversationResultBlock)callback {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject:_imClient.clientId];
    [array addObject:userId];
    [_imClient queryConversationsWithClientIds:array skip:0 limit:0 callback:^(NSArray *objects, NSError *error) {
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
    [_imClient createConversationWithName:nil clientIds:@[userId] attributes:@{CONV_TYPE:@(CDConvTypeSingle)} callback:callback];
}

-(void)createConvWithUserIds:(NSArray*)userIds callback:(AVIMConversationResultBlock)callback{
    NSString* name=[CDConvService nameOfUserIds:userIds];
    [_imClient createConversationWithName:name clientIds:userIds attributes:@{CONV_TYPE:@(CDConvTypeGroup)} callback:callback];
}

-(void)findGroupedConvsWithBlock:(AVArrayResultBlock)block{
    NSDictionary* attrs=@{CONV_TYPE:@(CDConvTypeGroup)};
    [_imClient queryConversationsWithName:nil andAttributes:attrs skip:0 limit:0 callback:block];
}

- (void)updateConv:(AVIMConversation *)conv name:(NSString *)name attrs:(NSDictionary *)attrs callback:(AVIMBooleanResultBlock)callback {
    AVIMConversationUpdateBuilder *builder = [conv newUpdateBuilder];
    if(name){
        builder.name = name;
    }
    if(attrs){
        builder.attributes = attrs;
    }
    [conv sendUpdate:[builder dictionary] callback:callback];
}

-(void)fetchConvsWithIds:(NSSet*)convids callback:(AVIMArrayResultBlock)callback{
    if(convids.count>0){
        [_imClient queryConversationByIds:[convids allObjects] callback:callback];
    }else{
        callback([NSMutableArray array],nil);
    }
}

#pragma mark - send or receive message

-(void)receiveMsg:(AVIMTypedMessage*)msg conv:(AVIMConversation*)conv{
    [CDUtils runInGlobalQueue:^{
        if(msg.mediaType==kAVIMMessageMediaTypeImage || msg.mediaType==kAVIMMessageMediaTypeAudio){
            NSString* path=[CDFileService getPathByObjectId:msg.messageId];
            NSFileManager* fileMan=[NSFileManager defaultManager];
            if([fileMan fileExistsAtPath:path]==NO){
                NSData* data=[msg.file getData];
                [data writeToFile:path atomically:YES];
            }
        }
        [CDUtils runInMainQueue:^{
            [_storage insertRoomWithConvid:conv.conversationId];
            [_storage insertMsg:msg];
            [_storage incrementUnreadWithConvid:conv.conversationId];
            [_notify postMsgNotify:msg];
        }];
    }];
}

#pragma mark - AVIMClientDelegate

- (void)imClientPaused:(AVIMClient *)imClient{
    DLog();
}

- (void)imClientResuming:(AVIMClient *)imClient{
    DLog();
}

- (void)imClientResumed:(AVIMClient *)imClient{
    DLog();
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

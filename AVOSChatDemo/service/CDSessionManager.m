//  CDSessionManager.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/29/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDSessionManager.h"
#import "CDCommon.h"
#import "CDMsg.h"
#import "CDRoom.h"
#import "CDFileService.h"
#import "CDUtils.h"
#import "CDCloudService.h"
#import "CDChatGroup.h"
#import "CDGroupService.h"
#import "AFNetworking.h"
#import "CDCacheService.h"
#import "CDDatabaseService.h"

@interface CDSessionManager () {
    AVSession *_session;
}

@end

#define MESSAGES @"messages"

static id instance = nil;
static BOOL initialized = NO;

@implementation CDSessionManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    if (!initialized) {
        [instance commonInit];
    }
    return instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        _session = [[AVSession alloc] init];
        _session.sessionDelegate = self;
        _session.signatureDelegate = self;
        [AVGroup setDefaultDelegate:self];
        [self commonInit];
    }
    return self;
}

//if type is image ,message is attment.objectId

- (void)commonInit {
    initialized = YES;
}

#pragma mark - session

-(void)openSession{
    [_session openWithPeerId:[AVUser currentUser].objectId];
}

-(void)closeSession{
    [_session close];
}

- (void)clearData {
    [self closeSession];
    initialized = NO;
}

#pragma mark - single chat

- (void)watchPeerId:(NSString *)peerId {
    NSLog(@"unwatch");
    [_session watchPeerIds:@[peerId] callback:^(BOOL succeeded, NSError *error) {
        [CDUtils logError:error callback:^{
            NSLog(@"watch succeed peerId=%@",peerId);
        }];
    }];
}

-(void)unwatchPeerId:(NSString*)peerId{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [_session unwatchPeerIds:@[peerId] callback:^(BOOL succeeded, NSError *error) {
        NSLog(@"unwatch callback");
        [CDUtils logError:error callback:^{
            NSLog(@"unwatch succeed");
        }];
    }];
}

#pragma mark - conversation

+(NSString*)convidOfSelfId:(NSString*)myId andOtherId:(NSString*)otherId{
    NSArray *arr=@[myId,otherId];
    NSArray *sortedArr=[arr sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableString* result= [[NSMutableString alloc] init];
    for(int i=0;i<sortedArr.count;i++){
        if(i!=0){
            [result appendString:@":"];
        }
        [result appendString:[sortedArr objectAtIndex:i]];
    }
    return [CDUtils md5OfString:result];
}

+(NSString*)getConvidOfRoomType:(CDConvType)roomType otherId:(NSString*)otherId groupId:(NSString*)groupId{
    if(roomType==CDConvTypeSingle){
        NSString* curUserId=[AVUser currentUser].objectId;
        return [CDSessionManager convidOfSelfId:curUserId andOtherId:otherId];
    }else{
        return groupId;
    }
}

#pragma mark - send message

-(CDMsg*)createMsgWithType:(CDMsgType)type objectId:(NSString*)objectId content:(NSString*)content toPeerId:(NSString*)toPeerId group:(AVGroup*)group{
    CDMsg* msg=[[CDMsg alloc] init];
    msg.toPeerId=toPeerId;
    int64_t currentTime=[[NSDate date] timeIntervalSince1970]*1000;
    msg.timestamp=currentTime;
    //NSLog(@"%@",[[NSDate dateWithTimeIntervalSince1970:msg.timestamp/1000] description]);
    msg.content=content;
    NSString* curUserId=[AVUser currentUser].objectId;
    msg.fromPeerId=curUserId;
    msg.status=CDMsgStatusSendStart;
    if(!group){
        msg.toPeerId=toPeerId;
        msg.roomType=CDConvTypeSingle;
    }else{
        msg.roomType=CDConvTypeGroup;
        msg.toPeerId=@"";
    }
    msg.readStatus=CDMsgReadStatusHaveRead;
    msg.convid=[CDSessionManager getConvidOfRoomType:msg.roomType otherId:msg.toPeerId groupId:group.groupId];
    if(objectId){
        msg.objectId=objectId;
    }else{
        msg.objectId=[CDUtils uuid];
    }
    msg.type=type;
    return msg;
}

-(AVSession*)getSession{
    return _session;
}

-(CDMsg*)sendMsg:(CDMsg*)msg group:(AVGroup*)group{
    if([_session isOpen]==NO || [_session isPaused]){
        //[CDUtils alert:@"会话暂停，请检查网络"];
    }
    if(!group){
        AVMessage *avMsg=[AVMessage messageForPeerWithSession:_session toPeerId:msg.toPeerId payload:[msg toMessagePayload]];
        [_session sendMessage:avMsg requestReceipt:YES];
    }else{
        AVMessage *avMsg=[AVMessage messageForGroup:group payload:[msg toMessagePayload]];
        [group sendMessage:avMsg];
    }
    return msg;
}

-(void)uploadFileMsg:(CDMsg*)msg block:(AVIdResultBlock)block{
    NSString* path=[CDFileService getPathByObjectId:msg.objectId];
    NSMutableString *name;
    name = [self getAVFileName];
    AVFile *f=[AVFile fileWithName:name contentsAtPath:path];
    [f saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            block(nil,error);
        }else{
            block(f,nil);
        }
    }];
}

-(void)convertAudioFile:(AVFile*)file block:(AVIdResultBlock)block{
    NSString* url=[@"https://leancloud.cn/1.1/qiniu/pfop/" stringByAppendingString:file.objectId];
    NSMutableURLRequest* request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:AVOSAppID forHTTPHeaderField:@"X-AVOSCloud-Application-Id"];
    [request setValue:AVOSAppKey forHTTPHeaderField:@"X-AVOSCloud-Application-Key"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary* params=@{@"fops":@"avthumb/aac"};
    
    NSData* data=[NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:nil];
    [request setHTTPBody:data];
    [request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    NSOperationQueue *queue=[[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse* res=(NSHTTPURLResponse*)response;
        NSDictionary* dict=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if(connectionError!=nil || [res statusCode]==200){
            [self runTwiceTimeWithTimes:0 avfile:file persistentId:[dict objectForKey:@"persistentId"] callback:block];
        }else{
            block(nil,[[NSError alloc] initWithDomain:[dict description] code:0 userInfo:nil]);
        }
    }];
}

-(void)uploadMsg:(CDMsg*)msg block:(AVIdResultBlock)block{
    [self uploadFileMsg:msg block:^(id object, NSError *error) {
        if(error){
            block(nil,error);
        }else{
            AVFile* file=(AVFile*)object;
            if(msg.type==CDMsgTypeImage){
                block(file.url,nil);
            }else if(msg.type==CDMsgTypeAudio){
                [self convertAudioFile:file block:block];
                //block(file.url,nil);
            }
        }
    }];
}

-(void)postUpdatedMsg:(CDMsg*)msg{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MESSAGE_UPDATED object:msg userInfo:nil];
}

-(void)postSessionUpdate{
   [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SESSION_UPDATED object:nil userInfo:nil];
}

- (void)sendCreatedMsg:(CDMsg *)msg group:(AVGroup*)group{
    if(msg.type==CDMsgTypeAudio || msg.type==CDMsgTypeImage){
        [self uploadMsg:msg block:^(id object, NSError *error) {
            if(error){
                [self setStatusFailedOfMsg:msg];
            }else{
                NSString* url=(NSString*)object;
                msg.content=url;
                [CDDatabaseService updateMsgWithId:msg.objectId content:url];
                [self sendMsg:msg group:group];
            }
        }];
    }else{
        [self sendMsg:msg group:group];
    }
}

- (void)sendMessageWithObjectId:(NSString*)objectId content:(NSString *)content type:(CDMsgType)type toPeerId:(NSString *)toPeerId group:(AVGroup*)group{
    CDMsg* msg=[self createMsgWithType:type objectId:objectId content:content toPeerId:toPeerId group:group];
    [CDDatabaseService insertMsgToDB:msg];
    [self postUpdatedMsg:msg];
    
    [self sendCreatedMsg:msg group:group];
}


-(void)resendMsg:(CDMsg*)msg toPeerId:(NSString*)toPeerId group:(AVGroup*)group{
    [self sendCreatedMsg:msg group:group];
    NSLog(@"resendMsg");
}

-(void)runTwiceTimeWithTimes:(int)times avfile:(AVFile*)file persistentId:(NSString*)persistentId callback:(AVIdResultBlock)callback{
    NSLog(@"times=%d",times);
    NSError* commonError=[NSError errorWithDomain:@"error" code:0 userInfo:@{NSLocalizedDescriptionKey:@"上传错误"}];
    if(times>=4){
        callback(nil,commonError);
    }else{
        [CDUtils runInGlobalQueue:^{
            sleep(times+1);
            [CDUtils runInMainQueue:^{
                NSString *url=@"http://api.qiniu.com/status/get/prefop";
                
                AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                [manager GET:url parameters:@{@"id":persistentId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSDictionary* dict=(NSDictionary*)responseObject;
                    NSArray* arr=[dict objectForKey:@"items"];
                    NSDictionary* result=[arr firstObject];
                    NSString* key=[result objectForKey:@"key"];
                    NSNumber* code=[result objectForKey:@"code"];
                    int codeInt=[code intValue];
                    if(codeInt==0){
                        NSString* finalUrl=[NSString stringWithFormat:@"http://ac-%@.qiniudn.com/%@",file.bucket,key];
                        callback(finalUrl,nil);
                    }else{
                        [self runTwiceTimeWithTimes:times+1 avfile:file persistentId:persistentId callback:callback];
                    }
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    callback(nil,error);
                }];
            }];
        }];
    }
}

-(void)sendAudioWithId:(NSString*)objectId toPeerId:(NSString*)toPeerId group:(AVGroup*)group callback:(AVBooleanResultBlock)callback{
    NSString* path=[CDFileService getPathByObjectId:objectId];
    AVFile* file=[AVFile fileWithName:[self getAVFileName] contentsAtPath:path];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            callback(succeeded,error);
        }else{
            NSString* url=[@"https://leancloud.cn/1.1/qiniu/pfop/" stringByAppendingString:file.objectId];
            NSMutableURLRequest* request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            [request setValue:AVOSAppID forHTTPHeaderField:@"X-AVOSCloud-Application-Id"];
            [request setValue:AVOSAppKey forHTTPHeaderField:@"X-AVOSCloud-Application-Key"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            NSDictionary* params=@{@"fops":@"avthumb/amr"};
            
            NSData* data=[NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:nil];
            [request setHTTPBody:data];
            [request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
            [request setHTTPMethod:@"POST"];
            NSOperationQueue *queue=[[NSOperationQueue alloc] init];
            [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSHTTPURLResponse* res=(NSHTTPURLResponse*)response;
                NSDictionary* dict=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSLog(@"%d %@",[res statusCode],dict);
                if(connectionError!=nil || [res statusCode]==200){
                    [self runTwiceTimeWithTimes:0 avfile:file persistentId:[dict objectForKey:@"persistentId"] callback:^(id object, NSError *error) {
                        if(error){
                            callback(NO,error);
                        }else{
                            [self sendMessageWithObjectId:objectId content:(NSString*)object type:CDMsgTypeAudio toPeerId:toPeerId group:group];
                            callback(YES,nil);
                        }
                    }];
                }else{
                    callback(NO,[[NSError alloc] initWithDomain:[dict description] code:0 userInfo:nil]);
                }
            }];
        }
    }];
}



- (NSMutableString *)getAVFileName {
    AVUser* curUser=[AVUser currentUser];
    double time=[[NSDate date] timeIntervalSince1970];
    NSMutableString *name=[[curUser username] mutableCopy];
    [name appendFormat:@"%f",time];
    return name;
}

#pragma mark - history message

- (void)getHistoryMessagesForPeerId:(NSString *)peerId callback:(AVArrayResultBlock)callback {
    AVHistoryMessageQuery *query = [AVHistoryMessageQuery queryWithFirstPeerId:_session.peerId secondPeerId:peerId];
    [query findInBackgroundWithCallback:callback];
}

- (void)getHistoryMessagesForGroup:(NSString *)groupId callback:(AVArrayResultBlock)callback {
    AVHistoryMessageQuery *query = [AVHistoryMessageQuery queryWithGroupId:groupId];
    [query findInBackgroundWithCallback:callback];
}

#pragma mark - comman message handle

-(void)didMessageSendFinish:(AVMessage*)avMsg group:(AVGroup*)group{
    CDMsg* msg=[CDMsg fromAVMessage:avMsg];
    msg.status=CDMsgStatusSendSucceed;
    [self setRoomTypeAndConvidOfMsg:msg group:group];
    [CDDatabaseService updateMsgWithId:msg.objectId status:msg.status timestamp:msg.timestamp];
    [self postUpdatedMsg:msg];
}

-(void)setStatusFailedOfMsg:(CDMsg*)msg{
    msg.status=CDMsgStatusSendFailed;
    [CDDatabaseService updateMsgWithId:msg.objectId status:CDMsgStatusSendFailed];
    // forbid to fast load message
    [self postUpdatedMsg:msg];
}

-(void)didMessageSendFailure:(AVMessage*)avMsg group:(AVGroup*)group{
    CDMsg* msg=[CDMsg fromAVMessage:avMsg];
    [self setRoomTypeAndConvidOfMsg:msg group:group];
    [self setStatusFailedOfMsg:msg];
}

-(void)didMessageArrived:(AVMessage*)avMsg{
    CDMsg* msg=[CDMsg fromAVMessage:avMsg];
    msg.status=CDMsgStatusSendReceived;
    [self setRoomTypeAndConvidOfMsg:msg group:nil];
    [CDDatabaseService updateMsgWithId:msg.objectId status:CDMsgStatusSendReceived];
    [self postUpdatedMsg:msg];
}

- (void)setRoomTypeAndConvidOfMsg:(CDMsg *)msg group:(AVGroup *)group {
    if(group){
        msg.roomType=CDConvTypeGroup;
        msg.convid=group.groupId;
    }else{
        assert(msg.toPeerId!=nil && msg.fromPeerId!=nil);
        msg.roomType=CDConvTypeSingle;
        msg.convid=[CDSessionManager convidOfSelfId:msg.toPeerId andOtherId:msg.fromPeerId];
    }
}

-(void)didReceiveAVMessage:(AVMessage*)avMsg group:(AVGroup*)group{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    NSLog(@"payload=%@",avMsg.payload);
    CDMsg* msg=[CDMsg fromAVMessage:avMsg];
    [self setRoomTypeAndConvidOfMsg:msg group:group];
    msg.status=CDMsgStatusSendReceived;
    msg.readStatus=CDMsgReadStatusUnread;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if(msg.type==CDMsgTypeImage || msg.type==CDMsgTypeAudio){
            NSString* path=[CDFileService getPathByObjectId:msg.objectId];
            NSFileManager* fileMan=[NSFileManager defaultManager];
            if([fileMan fileExistsAtPath:path]==NO){
                NSString* url=msg.content;
                AVFile* file=[AVFile fileWithURL:url];
                NSData* data=[file getData];
                [data writeToFile:path atomically:YES];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [CDDatabaseService insertMsgToDB:msg];
            [self postUpdatedMsg:msg];
        });
    });
}

#pragma mark - AVSessionDelegate
- (void)sessionOpened:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
    [self postSessionUpdate];
}

- (void)sessionPaused:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
    [self postSessionUpdate];
}

- (void)sessionResumed:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
    [self postSessionUpdate];
}

- (void)session:(AVSession *)session didReceiveMessage:(AVMessage *)message {
    [self didReceiveAVMessage:message group:nil];
}

- (void)session:(AVSession *)session messageSendFailed:(AVMessage *)message error:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ message:%@ toPeerId:%@ error:%@", session.peerId, message.payload, message.toPeerId, error);
    [self didMessageSendFailure:message group:nil];
}

- (void)session:(AVSession *)session messageSendFinished:(AVMessage *)message {
    [self didMessageSendFinish:message group:nil];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ message:%@ toPeerId:%@", session.peerId, message.payload, message.toPeerId);
}

- (void)session:(AVSession *)session didReceiveStatus:(AVPeerStatus)status peerIds:(NSArray *)peerIds {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ peerIds:%@ status:%@", session.peerId, peerIds, status==AVPeerStatusOffline?@"offline":@"online");
}

- (void)sessionFailed:(AVSession *)session error:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ error:%@", session.peerId, error);
}

- (void)session:(AVSession *)session messageArrived:(AVMessage *)message{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    NSLog(@"%@",message);
    [self didMessageArrived:message];
}


#pragma mark - AVGroupDelegate

- (void)group:(AVGroup *)group didReceiveMessage:(AVMessage *)message {
    [self didReceiveAVMessage:message group:group];
}

- (void)group:(AVGroup *)group didReceiveEvent:(AVGroupEvent)event peerIds:(NSArray *)peerIds {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ event:%u peerIds:%@", group.groupId, event, peerIds);
    if(event==AVGroupEventSelfLeft){
        [CDUtils notifyGroupUpdate];
    }
}

- (void)group:(AVGroup *)group messageSendFinished:(AVMessage *)message {
    [self didMessageSendFinish:message group:group];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ message:%@", group.groupId, message.payload);
}

- (void)group:(AVGroup *)group messageSendFailed:(AVMessage *)message error:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ message:%@ error:%@", group.groupId, message.payload, error);
    [self didMessageSendFailure:message group:group];
}

- (void)session:(AVSession *)session group:(AVGroup *)group messageSent:(NSString *)message success:(BOOL)success {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ message:%@ success:%d", group.groupId, message, success);
}

#pragma mark - signature

//- (AVSignature *)signatureForPeerWithPeerId:(NSString *)peerId watchedPeerIds:(NSArray *)watchedPeerIds action:(NSString *)action{
//    if(watchedPeerIds==nil){
//        watchedPeerIds=[[NSMutableArray alloc] init];
//    }
//    NSDictionary* result=[CDCloudService signWithPeerId:peerId watchedPeerIds:watchedPeerIds];
//    return [self getAVSignatureWithParams:result peerIds:watchedPeerIds];
//}
//
//-(AVSignature*)getAVSignatureWithParams:(NSDictionary*) fields peerIds:(NSArray*)peerIds{
//    AVSignature* avSignature=[[AVSignature alloc] init];
//    NSNumber* timestampNum=[fields objectForKey:@"timestamp"];
//    long timestamp=[timestampNum longValue];
//    NSString* nonce=[fields objectForKey:@"nonce"];
//    NSString* signature=[fields objectForKey:@"signature"];
//    
//    [avSignature setTimestamp:timestamp];
//    [avSignature setNonce:nonce];
//    [avSignature setSignature:signature];;
//    [avSignature setSignedPeerIds:[peerIds copy]];
//    return avSignature;
//}
//
//-(AVSignature*)signatureForGroupWithPeerId:(NSString *)peerId groupId:(NSString *)groupId groupPeerIds:(NSArray *)groupPeerIds action:(NSString *)action{
//    NSDictionary* result=[CDCloudService groupSignWithPeerId:peerId groupId:groupId groupPeerIds:groupPeerIds action:action];
//    return [self getAVSignatureWithParams:result peerIds:groupPeerIds];
//}

@end

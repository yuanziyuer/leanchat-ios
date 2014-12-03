//  CDSessionManager.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/29/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDSessionManager.h"
#import "CDCommon.h"
#import "CDMsg.h"
#import "CDChatRoom.h"
#import "CDUtils.h"
#import "CDCloudService.h"
#import "CDChatGroup.h"
#import "CDGroupService.h"
#import "AFNetworking.h"
#import "QiniuSDK.h"
#import "CDCacheService.h"
#import "CDDatabaseService.h"

@interface CDSessionManager () {
    AVSession *session;
    QNUploadManager *upManager;
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

- (NSString *)databasePath {
    static NSString *databasePath = nil;
    if (!databasePath) {
        NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        databasePath = [cacheDirectory stringByAppendingPathComponent:@"chat.db"];
    }
    return databasePath;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        
        session = [[AVSession alloc] init];
        session.sessionDelegate = self;
        session.signatureDelegate = self;
        [self commonInit];
    }
    return self;
}

//if type is image ,message is attment.objectId

- (void)commonInit {
    upManager=[[QNUploadManager alloc] init];
    initialized = YES;
}

#pragma mark - session

-(void)openSession{
    [session openWithPeerId:[AVUser currentUser].objectId];
}

-(void)closeSession{
    [session close];
}

- (void)clearData {
    [session close];
    initialized = NO;
}

#pragma mark - single chat

- (void)watchPeerId:(NSString *)peerId {
    NSLog(@"unwatch");
    [session watchPeerIds:@[peerId] callback:^(BOOL succeeded, NSError *error) {
        [CDUtils logError:error callback:^{
            NSLog(@"watch succeed peerId=%@",peerId);
        }];
    }];
}

-(void)unwatchPeerId:(NSString*)peerId{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [session unwatchPeerIds:@[peerId] callback:^(BOOL succeeded, NSError *error) {
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


+(NSString*)uuid{
    NSString *chars=@"abcdefghijklmnopgrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    assert(chars.length==62);
    int len=chars.length;
    NSMutableString* result=[[NSMutableString alloc] init];
    for(int i=0;i<24;i++){
        int p=arc4random_uniform(len);
        NSRange range=NSMakeRange(p, 1);
        [result appendString:[chars substringWithRange:range]];
    }
    return result;
}

+(NSString*)getConvidOfRoomType:(CDMsgRoomType)roomType otherId:(NSString*)otherId groupId:(NSString*)groupId{
    if(roomType==CDMsgRoomTypeSingle){
        NSString* curUserId=[AVUser currentUser].objectId;
        return [CDSessionManager convidOfSelfId:curUserId andOtherId:otherId];
    }else{
        return groupId;
    }
}

#pragma mark - send message

-(CDMsg*)createAndSendMsgWithObjectId:(NSString*)objectId type:(CDMsgType)type content:(NSString*)content toPeerId:(NSString*)toPeerId group:(AVGroup*)group{
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
        msg.roomType=CDMsgRoomTypeSingle;
    }else{
        msg.roomType=CDMsgRoomTypeGroup;
        msg.toPeerId=@"";
    }
    msg.readStatus=CDMsgReadStatusHaveRead;
    msg.convid=[CDSessionManager getConvidOfRoomType:msg.roomType otherId:msg.toPeerId groupId:group.groupId];
    msg.objectId=objectId;
    msg.type=type;
    return [self sendMsg:msg group:group];
}

-(CDMsg*)createAndSendMsgWithType:(CDMsgType)type content:(NSString*)content toPeerId:(NSString*)toPeerId group:(AVGroup*)group{
    return [self createAndSendMsgWithObjectId:[CDSessionManager uuid] type:type content:content toPeerId:toPeerId group:group];
}

-(AVSession*)getSession{
    return session;
}

-(CDMsg*)sendMsg:(CDMsg*)msg group:(AVGroup*)group{
    if(!group){
        AVMessage *avMsg=[AVMessage messageForPeerWithSession:session toPeerId:msg.toPeerId payload:[msg toMessagePayload]];
        [session sendMessage:avMsg];
    }else{
        AVMessage *avMsg=[AVMessage messageForGroup:group payload:[msg toMessagePayload]];
        [group sendMessage:avMsg];
    }
    return msg;
}

- (void)sendMessageWithType:(CDMsgType)type content:(NSString *)content  toPeerId:(NSString *)toPeerId group:(AVGroup*)group{
    CDMsg* msg=[self createAndSendMsgWithType:type content:content toPeerId:toPeerId group:group];
    [self insertMessageToDBAndNotify:msg];
}

- (void)sendMessageWithObjectId:(NSString*)objectId content:(NSString *)content type:(CDMsgType)type toPeerId:(NSString *)toPeerId group:(AVGroup*)group{
    CDMsg* msg=[self createAndSendMsgWithObjectId:objectId type:type content:content toPeerId:toPeerId group:group];
    [self insertMessageToDBAndNotify:msg];
}

-(void)runTwiceTimeWithTimes:(int)times persistentId:(NSString*)persistentId callback:(AVIdResultBlock)callback{
    NSLog(@"times=%d",times);
    NSError* commonError=[NSError errorWithDomain:@"error" code:0 userInfo:@{NSLocalizedDescriptionKey:@"上传错误"}];
    if(times>=2){
        callback(nil,commonError);
    }else{
        [CDUtils runInGlobalQueue:^{
            sleep(1);
            [CDUtils runInMainQueue:^{
                NSString *url=@"http://api.qiniu.com/status/get/prefop";
                AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                [manager GET:url parameters:@{@"id":persistentId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSDictionary* dict=(NSDictionary*)responseObject;
                    NSLog(@"%@",dict);
                    NSArray* arr=[dict objectForKey:@"items"];
                    NSDictionary* result=[arr firstObject];
                    NSString* key=[result objectForKey:@"key"];
                    NSNumber* code=[result objectForKey:@"code"];
                    int codeInt=[code intValue];
                    if(codeInt==0){
                        NSString* finalUrl=[@"http://lzw-love.qiniudn.com/" stringByAppendingString:key];
                        callback(finalUrl,nil);
                    }else{
                        [self runTwiceTimeWithTimes:times+1 persistentId:persistentId callback:callback];
                    }
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    callback(nil,error);
                }];
            }];
        }];
    }
}

-(void)sendAudioWithId:(NSString*)objectId toPeerId:(NSString*)toPeerId group:(AVGroup*)group callback:(AVBooleanResultBlock)callback{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString* path=[CDSessionManager getPathByObjectId:objectId];
    [manager GET:@"https://leanchat.avosapps.com/qiniuToken" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* dict=(NSDictionary*)responseObject;
        NSString* token=[dict objectForKey:@"token"];
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        [upManager putData:data key:objectId token:token
                  complete: ^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                      if(info.error){
                          callback(NO,info.error);
                      }else{
                          [self runTwiceTimeWithTimes:0 persistentId:[resp objectForKey:@"persistentId"] callback:^(id object, NSError *error) {
                              if(error){
                                  callback(NO,error);
                              }else{
                                  [self sendMessageWithObjectId:objectId content:(NSString*)object type:CDMsgTypeAudio toPeerId:toPeerId group:group];
                                  callback(YES,nil);
                              }
                          }];
                      }
                  } option:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        callback(NO,error);
    }];
}

+(NSString*)getFilesPath{
    NSString* appPath=[NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filesPath=[appPath stringByAppendingString:@"/files/"];
    NSFileManager *fileMan=[NSFileManager defaultManager];
    NSError *error;
    BOOL isDir=YES;
    if([fileMan fileExistsAtPath:filesPath isDirectory:&isDir]==NO){
        [fileMan createDirectoryAtPath:filesPath withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            [NSException raise:@"error when create dir" format:@"error"];
        }
    }
    return filesPath;
}

+(NSString*)getPathByObjectId:(NSString*)objectId{
    return [[self getFilesPath] stringByAppendingString:objectId];
}

- (void)sendAttachmentWithObjectId:(NSString*)objectId type:(CDMsgType)type toPeerId:(NSString *)toPeerId group:(AVGroup*)group{
    NSString* path=[CDSessionManager getPathByObjectId:objectId];
    AVUser* curUser=[AVUser currentUser];
    double time=[[NSDate date] timeIntervalSince1970];
    NSMutableString *name=[[curUser username] mutableCopy];
    [name appendFormat:@"%f",time];
    AVFile *f=[AVFile fileWithName:name contentsAtPath:path];
    [f saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            [CDUtils alert:[error localizedDescription]];
        }else{
            [self sendMessageWithObjectId:objectId content:f.url type:type toPeerId:toPeerId group:group];
        }
    }];
}

- (void )insertMessageToDBAndNotify:(CDMsg*)msg{
    [CDDatabaseService insertMsgToDB:msg];
    [self notifyMessageUpdate];
}

-(void)notifyMessageUpdate{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MESSAGE_UPDATED object:nil userInfo:nil];
}

#pragma mark - history message

- (void)getHistoryMessagesForPeerId:(NSString *)peerId callback:(AVArrayResultBlock)callback {
    AVHistoryMessageQuery *query = [AVHistoryMessageQuery queryWithFirstPeerId:session.peerId secondPeerId:peerId];
    [query findInBackgroundWithCallback:callback];
}

- (void)getHistoryMessagesForGroup:(NSString *)groupId callback:(AVArrayResultBlock)callback {
    AVHistoryMessageQuery *query = [AVHistoryMessageQuery queryWithGroupId:groupId];
    [query findInBackgroundWithCallback:callback];
}

#pragma mark - comman message handle

-(void)messageSendFinish:(AVMessage*)avMsg group:(AVGroup*)group{
    CDMsg* msg=[CDMsg fromAVMessage:avMsg];
    [CDDatabaseService updateMsgWithId:msg.objectId status:CDMsgStatusSendSucceed];
    [self notifyMessageUpdate];
}

-(void)messageSendFailure:(AVMessage*)avMsg group:(AVGroup*)group{
    NSString* objectId=[CDMsg getObjectIdByAVMessage:avMsg];
    [CDDatabaseService updateMsgWithId:objectId status:CDMsgStatusSendFailed];
    [self notifyMessageUpdate];
}

-(void)didReceiveAVMessage:(AVMessage*)avMsg group:(AVGroup*)group{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    NSLog(@"payload=%@",avMsg.payload);
    CDMsg* msg=[CDMsg fromAVMessage:avMsg];
    if(group){
        msg.roomType=CDMsgRoomTypeGroup;
        msg.convid=group.groupId;
    }else{
        msg.roomType=CDMsgRoomTypeSingle;
        msg.convid=[CDSessionManager convidOfSelfId:[AVUser currentUser].objectId andOtherId:avMsg.fromPeerId];
    }
    msg.status=CDMsgStatusSendReceived;
    msg.readStatus=CDMsgReadStatusUnread;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if(msg.type==CDMsgTypeImage || msg.type==CDMsgTypeAudio){
            NSString* path=[CDSessionManager getPathByObjectId:msg.objectId];
            NSFileManager* fileMan=[NSFileManager defaultManager];
            if([fileMan fileExistsAtPath:path]==NO){
                NSData* data=[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:msg.content]];
                NSError* error;
                [data writeToFile:path options:NSDataWritingAtomic error:&error];
                if(error==nil){
                }else{
                    NSLog(@"error when download file");
                    return ;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self insertMessageToDBAndNotify:msg];
        });
    });
}

#pragma mark - AVSessionDelegate
- (void)sessionOpened:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
}

- (void)sessionPaused:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
}

- (void)sessionResumed:(AVSession *)session {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@", session.peerId);
}

- (void)session:(AVSession *)session didReceiveMessage:(AVMessage *)message {
    [self didReceiveAVMessage:message group:nil];
}

- (void)session:(AVSession *)session messageSendFailed:(AVMessage *)message error:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"session:%@ message:%@ toPeerId:%@ error:%@", session.peerId, message.payload, message.toPeerId, error);
    [self messageSendFailure:message group:nil];
}

- (void)session:(AVSession *)session messageSendFinished:(AVMessage *)message {
    [self messageSendFinish:message group:nil];
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


#pragma mark - AVGroupDelegate

- (void)group:(AVGroup *)group didReceiveMessage:(AVMessage *)message {
    [self didReceiveAVMessage:message group:group];
    //[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SESSION_UPDATED object:group.session userInfo:nil];

}

- (void)group:(AVGroup *)group didReceiveEvent:(AVGroupEvent)event peerIds:(NSArray *)peerIds {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ event:%u peerIds:%@", group.groupId, event, peerIds);
    if(event==AVGroupEventSelfLeft){
        [CDUtils notifyGroupUpdate];
    }
}

- (void)group:(AVGroup *)group messageSendFinished:(AVMessage *)message {
    [self messageSendFinish:message group:group];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ message:%@", group.groupId, message.payload);
}

- (void)group:(AVGroup *)group messageSendFailed:(AVMessage *)message error:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"group:%@ message:%@ error:%@", group.groupId, message.payload, error);

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

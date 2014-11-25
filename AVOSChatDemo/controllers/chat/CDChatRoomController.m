//
//  CDChatRoomController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/28/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDChatRoomController.h"
#import "CDSessionManager.h"
#import "CDChatDetailController.h"
#import "QBImagePickerController.h"
#import "UIImage+Resize.h"
#import "CDUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CDGroupDetailController.h"
#import "CDGroupAddMemberController.h"
#import "XHDisplayTextViewController.h"
#import "XHDisplayMediaViewController.h"
#import "XHDisplayLocationViewController.h"
#import "CDEmotionUtils.h"

#import "XHContactDetailTableViewController.h"

#import "XHAudioPlayerHelper.h"

@interface CDChatRoomController () <UINavigationControllerDelegate> {
    NSMutableDictionary *_loadedData;
    CDSessionManager* sessionManager;
}

@property (nonatomic, strong) XHMessageTableViewCell *currentSelectedCell;
@property (nonatomic, strong) NSArray *emotionManagers;


@end

@implementation CDChatRoomController

#pragma mark - View lifecycle

/**
 *  Override point for customization.
 * *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` and `JSQMessagesCollectionView` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    _loadedData = [[NSMutableDictionary alloc] init];
    sessionManager=[CDSessionManager sharedInstance];
    
    /**
     *  You MUST set your senderId and display name
     */
    AVUser* curUser=[AVUser currentUser];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop                                                                                          target:self                                                                                          action:@selector(backPressed:)];
    
    if(self.type==CDMsgRoomTypeGroup){
        UIImage* peopleImage=[UIImage imageNamed:@"chat_menu_people"];
        UIImage* _peopleImage=[CDUtils imageWithImage:peopleImage scaledToSize:CGSizeMake(25, 25)];
        UIBarButtonItem* item=[[UIBarButtonItem alloc] initWithImage:_peopleImage style:UIBarButtonItemStyleDone target:self action:@selector(goChatGroupDetail:)];
        self.navigationItem.rightBarButtonItem=item;
    }
    
    if(self.type==CDMsgRoomTypeSingle){
        [sessionManager watchPeerId:self.chatUser.objectId ];
    }else{
        _group=[sessionManager joinGroupById:_chatGroup.objectId];
    }
    
    if (self.type == CDMsgRoomTypeGroup) {
        self.title = [_chatGroup getTitle];
    } else {
        self.title = self.chatUser.username;
    }
    
    // Custom UI
    //    [self setBackgroundColor:[UIColor clearColor]];
    //    [self setBackgroundImage:[UIImage imageNamed:@"TableViewBackgroundImage"]];
    
    // 设置自身用户名
    self.messageSender = [curUser username];
    
    // 添加第三方接入数据
    NSMutableArray *shareMenuItems = [NSMutableArray array];
    NSArray *plugIcons = @[@"sharemore_pic", @"sharemore_video"];
    NSArray *plugTitle = @[@"照片", @"拍摄"];
    for (NSString *plugIcon in plugIcons) {
        XHShareMenuItem *shareMenuItem = [[XHShareMenuItem alloc] initWithNormalIconImage:[UIImage imageNamed:plugIcon] title:[plugTitle objectAtIndex:[plugIcons indexOfObject:plugIcon]]];
        [shareMenuItems addObject:shareMenuItem];
    }
   
    _emotionManagers=[CDEmotionUtils getEmotionManagers];
    self.emotionManagerView.isShowEmotionStoreButton=NO;
    [self.emotionManagerView reloadData];
    
    self.shareMenuItems = shareMenuItems;
    [self.shareMenuView reloadData];
    

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageUpdated:) name:NOTIFICATION_MESSAGE_UPDATED object:nil];
    [self messageUpdated:nil];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    NSNotificationCenter* center=[NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NOTIFICATION_MESSAGE_UPDATED object:nil];
}

-(void)dealloc{
    self.emotionManagers = nil;
    [[XHAudioPlayerHelper shareInstance] setDelegate:nil];
    if(self.type==CDMsgRoomTypeSingle){
        [sessionManager unwatchPeerId:self.chatUser.objectId];
    }
}

-(void)backPressed:(id)sender{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark message data

-(UIImage*)getImageByMsg:(CDMsg*)msg{
    if(msg.type==CDMsgTypeImage){
        UIImage* image = [_loadedData objectForKey:msg.objectId];
        if (image) {
            return image;
        } else {
            NSString* path=[CDSessionManager getPathByObjectId:msg.objectId];
            NSFileManager* fileMan=[NSFileManager defaultManager];
            //NSLog(@"path=%@",path);
            if([fileMan fileExistsAtPath:path]){
                NSData* data=[fileMan contentsAtPath:path];
                UIImage* image=[UIImage imageWithData:data];
                [_loadedData setObject:image forKey:msg.objectId];
                return image;
            }else{
                NSLog(@"does not exists image file");
            }
        }
    }
    return nil;
}

-(XHMessage*)getXHMessageByMsg:(CDMsg*)msg{
    AVUser* fromUser=[sessionManager lookupUser:msg.fromPeerId];
    AVUser* curUser=[AVUser currentUser];
    XHMessage* xhMessage;
    if(msg.type==CDMsgTypeText){
        xhMessage=[[XHMessage alloc] initWithText:msg.content sender:fromUser.username timestamp:[msg getTimestampDate]];
    }else if(msg.type==CDMsgTypeAudio){
        NSString* objectId=msg.objectId;
        NSString* path=[CDSessionManager getPathByObjectId:objectId];
        NSDictionary* fileAttrs=[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
        unsigned long long size=[fileAttrs fileSize];
        int oneSecSize=15000;
        int duration=(int)(size*1.0f/oneSecSize+1);
        xhMessage=[[XHMessage alloc] initWithVoicePath:path voiceUrl:msg.content voiceDuration:[NSString stringWithFormat:@"%d",duration] sender:fromUser.username timestamp:[msg getTimestampDate]];
    }else if(msg.type==CDMsgTypeLocation){
        NSArray* parts=[msg.content componentsSeparatedByString:@"&"];
        double latitude=[[parts objectAtIndex:1] doubleValue];
        double longitude=[[parts objectAtIndex:2] doubleValue];
        
        xhMessage=[[XHMessage alloc] initWithLocalPositionPhoto:[UIImage imageNamed:@"Fav_Cell_Loc"] geolocations:[parts objectAtIndex:0] location:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] sender:fromUser.username timestamp:[msg getTimestampDate]];
    }else if(msg.type==CDMsgTypeImage){
        xhMessage=[[XHMessage alloc] initWithPhoto:[self getImageByMsg:msg] thumbnailUrl:msg.content originPhotoUrl:msg.content sender:fromUser.username timestamp:[msg getTimestampDate]];
    }
    xhMessage.avator=[self getAvatarByMsg:msg];
    xhMessage.avatorUrl=nil;
    if([curUser.objectId isEqualToString:msg.fromPeerId]){
        xhMessage.bubbleMessageType=XHBubbleMessageTypeSending;
    }else{
        xhMessage.bubbleMessageType=XHBubbleMessageTypeReceiving;
    }
    return xhMessage;
}

-(UIImage*)getAvatarByMsg:(CDMsg*)msg{
    __block UIImage* avatar=[_loadedData objectForKey:msg.fromPeerId];
    if(avatar){
        return avatar;
    }else{
        AVUser* user=[sessionManager lookupUser:msg.fromPeerId];
        SDWebImageManager* man=[SDWebImageManager sharedManager];
        AVFile* avatarFile=[user objectForKey:@"avatar"];
        [man downloadImageWithURL:[NSURL URLWithString:[avatarFile url]] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if(error){
                [CDUtils alertError:error];
            }else{
                [_loadedData setObject:image forKey:msg.fromPeerId];
            }
            avatar=image;
        }];
    }
    if(avatar==nil){
        avatar=[UIImage imageNamed:@"default_user_avatar"];
    }
    return avatar;
}

#pragma mark next controller

- (void)goChatGroupDetail:(id)sender {
//    CDGroupDetailController *controller=[[CDGroupDetailController alloc] init];
//    controller.chatGroup=self.chatGroup;
//    [self.navigationController pushViewController: controller animated:YES];

    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    [flow setItemSize:CGSizeMake(240, 240)];
    [flow setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    CDGroupDetailController* controller=[[CDGroupDetailController alloc] initWithNibName:@"CDGroupDetailController" bundle:nil];
    controller.chatGroup=self.chatGroup;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark messageUpdated

- (void)messageUpdated:(NSNotification *)notification {
    NSString* convid=[CDSessionManager getConvidOfRoomType:self.type otherId:self.chatUser.objectId groupId:self.group.groupId];
    NSMutableArray *msgs  = [[sessionManager getMsgsForConvid:convid] mutableCopy];
    //UIApplication* app=[UIApplication sharedApplication];
    //app.networkActivityIndicatorVisible=YES;
    //[[self.toolbarItems objectAtIndex:0] addSubview:view];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(CDMsg* msg in msgs){
            [self getAvatarByMsg:msg];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //app.networkActivityIndicatorVisible=NO;
            //[indicator removeFromSuperview];
            self.messages=[[NSMutableArray alloc] init];
            for(CDMsg* msg in msgs){
                [self.messages addObject:[self getXHMessageByMsg:msg]];
            }
            [self.messageTableView reloadData];
            [self scrollToBottomAnimated:YES];
        });
    });
}

#pragma send message

- (void)sendAttachmentWithObjectId:(NSString *)objectId type:(CDMsgType)type{
    [sessionManager sendAttachmentWithObjectId:objectId type:type toPeerId:self.chatUser.objectId group:self.group];
}

-(void)sendImage:(UIImage*)image{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    
    NSString* objectId=[CDSessionManager uuid];
    NSString* path=[CDSessionManager getPathByObjectId:objectId];
    NSError* error;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    NSLog(@" save path=%@",path);
    if(error==nil){
        [self sendAttachmentWithObjectId:objectId type:CDMsgTypeImage];
    }else{
        [CDUtils alert:@"write image to file error"];
    }
}

#pragma mark - LifeCycle

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[XHAudioPlayerHelper shareInstance] stopAudio];
}

- (id)init {
    self = [super init];
    if (self) {
        // 配置输入框UI的样式
        //        self.allowsSendVoice = NO;
        //        self.allowsSendFace = NO;
        //        self.allowsSendMultiMedia = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 [self removeMessageAtIndexPath:indexPath];
 [self insertOldMessages:self.messages];
 */

#pragma mark - XHMessageTableViewCell delegate

- (void)multiMediaMessageDidSelectedOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath onMessageTableViewCell:(XHMessageTableViewCell *)messageTableViewCell {
    UIViewController *disPlayViewController;
    switch (message.messageMediaType) {
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypePhoto: {
            DLog(@"message : %@", message.photo);
            DLog(@"message : %@", message.videoConverPhoto);
            XHDisplayMediaViewController *messageDisplayTextView = [[XHDisplayMediaViewController alloc] init];
            messageDisplayTextView.message = message;
            disPlayViewController = messageDisplayTextView;
            break;
        }
            break;
        case XHBubbleMessageMediaTypeVoice: {
            DLog(@"message : %@", message.voicePath);
            
            // Mark the voice as read and hide the red dot.
            //message.isRead = YES;
            //messageTableViewCell.messageBubbleView.voiceUnreadDotImageView.hidden = YES;
            
            [[XHAudioPlayerHelper shareInstance] setDelegate:self];
            if (_currentSelectedCell) {
                [_currentSelectedCell.messageBubbleView.animationVoiceImageView stopAnimating];
            }
            if (_currentSelectedCell == messageTableViewCell) {
                [messageTableViewCell.messageBubbleView.animationVoiceImageView stopAnimating];
                [[XHAudioPlayerHelper shareInstance] stopAudio];
                self.currentSelectedCell = nil;
            } else {
                self.currentSelectedCell = messageTableViewCell;
                [messageTableViewCell.messageBubbleView.animationVoiceImageView startAnimating];
                [[XHAudioPlayerHelper shareInstance] managerAudioWithFileName:message.voicePath toPlay:YES];
            }
            break;
        }
        case XHBubbleMessageMediaTypeEmotion:
            DLog(@"facePath : %@", message.emotionPath);
            break;
        case XHBubbleMessageMediaTypeLocalPosition: {
            DLog(@"facePath : %@", message.localPositionPhoto);
            XHDisplayLocationViewController *displayLocationViewController = [[XHDisplayLocationViewController alloc] init];
            displayLocationViewController.message = message;
            disPlayViewController = displayLocationViewController;
            break;
        }
        default:
            break;
    }
    if (disPlayViewController) {
        [self.navigationController pushViewController:disPlayViewController animated:YES];
    }
}

- (void)didDoubleSelectedOnTextMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    DLog(@"text : %@", message.text);
    XHDisplayTextViewController *displayTextViewController = [[XHDisplayTextViewController alloc] init];
    displayTextViewController.message = message;
    [self.navigationController pushViewController:displayTextViewController animated:YES];
}

- (void)didSelectedAvatorOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    DLog(@"indexPath : %@", indexPath);
    XHContact *contact = [[XHContact alloc] init];
    contact.contactName = [message sender];
    contact.contactIntroduction = @"自定义描述，这个需要和业务逻辑挂钩";
    XHContactDetailTableViewController *contactDetailTableViewController = [[XHContactDetailTableViewController alloc] initWithContact:contact];
    [self.navigationController pushViewController:contactDetailTableViewController animated:YES];
}

- (void)menuDidSelectedAtBubbleMessageMenuSelecteType:(XHBubbleMessageMenuSelecteType)bubbleMessageMenuSelecteType {
    
}

#pragma mark - XHAudioPlayerHelper Delegate

- (void)didAudioPlayerStopPlay:(AVAudioPlayer *)audioPlayer {
    if (!_currentSelectedCell) {
        return;
    }
    [_currentSelectedCell.messageBubbleView.animationVoiceImageView stopAnimating];
    self.currentSelectedCell = nil;
}

#pragma mark - XHEmotionManagerView DataSource

- (NSInteger)numberOfEmotionManagers {
    return self.emotionManagers.count;
}

- (XHEmotionManager *)emotionManagerForColumn:(NSInteger)column {
    return [self.emotionManagers objectAtIndex:column];
}

- (NSArray *)emotionManagersAtManager {
    return self.emotionManagers;
}

#pragma mark - XHMessageTableViewController Delegate

- (BOOL)shouldLoadMoreMessagesScrollToTop {
    return YES;
}

- (void)loadMoreMessagesScrollTotop {
    if (!self.loadingMoreMessage) {
        self.loadingMoreMessage = YES;
        
        WEAKSELF
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *messages = [[NSMutableArray alloc] init];
            sleep(2);
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf insertOldMessages:messages];
                weakSelf.loadingMoreMessage = NO;
            });
        });
    }
}

/**
 *  发送文本消息的回调方法
 *
 *  @param text   目标文本字符串
 *  @param sender 发送者的名字
 *  @param date   发送时间
 */
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
    [sessionManager sendMessageWithType:CDMsgTypeText content:text
                               toPeerId:self.chatUser.objectId group:self.group];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
}

/**
 *  发送图片消息的回调方法
 *
 *  @param photo  目标图片对象，后续有可能会换
 *  @param sender 发送者的名字
 *  @param date   发送时间
 */
- (void)didSendPhoto:(UIImage *)photo fromSender:(NSString *)sender onDate:(NSDate *)date {
    [self sendImage:photo];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypePhoto];
}

/**
 *  发送视频消息的回调方法
 *
 *  @param videoPath 目标视频本地路径
 *  @param sender    发送者的名字
 *  @param date      发送时间
 */
- (void)didSendVideoConverPhoto:(UIImage *)videoConverPhoto videoPath:(NSString *)videoPath fromSender:(NSString *)sender onDate:(NSDate *)date {
}

/**
 *  发送语音消息的回调方法
 *
 *  @param voicePath        目标语音本地路径
 *  @param voiceDuration    目标语音时长
 *  @param sender           发送者的名字
 *  @param date             发送时间
 */
- (void)didSendVoice:(NSString *)voicePath voiceDuration:(NSString *)voiceDuration fromSender:(NSString *)sender onDate:(NSDate *)date {
    NSString* objectId=[CDSessionManager uuid];
    NSString* path=[CDSessionManager getPathByObjectId:objectId];
    NSError* error;
    [[NSFileManager defaultManager] copyItemAtPath:voicePath toPath:path error:&error];
    if(error==nil){
        [self sendAttachmentWithObjectId:objectId type:CDMsgTypeAudio];
    }else{
        [CDUtils alertError:error];
    }
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeVoice];
}

/**
 *  发送第三方表情消息的回调方法
 *
 *  @param facePath 目标第三方表情的本地路径
 *  @param sender   发送者的名字
 *  @param date     发送时间
 */
- (void)didSendEmotion:(NSString *)emotion fromSender:(NSString *)sender onDate:(NSDate *)date {
    UITextView *textView=self.messageInputView.inputTextView;
    NSRange range=[textView selectedRange];
    NSMutableString* str=[[NSMutableString alloc] initWithString:textView.text];
    [str deleteCharactersInRange:range];
    [str insertString:emotion atIndex:range.location];
    textView.text=str;
    textView.selectedRange=NSMakeRange(range.location+emotion.length, 0);
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeEmotion];
}

- (void)didSendGeoLocationsPhoto:(UIImage *)geoLocationsPhoto geolocations:(NSString *)geolocations location:(CLLocation *)location fromSender:(NSString *)sender onDate:(NSDate *)date {
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeLocalPosition];
}

/**
 *  是否显示时间轴Label的回调方法
 *
 *  @param indexPath 目标消息的位置IndexPath
 *
 *  @return 根据indexPath获取消息的Model的对象，从而判断返回YES or NO来控制是否显示时间轴Label
 */
- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row==0){
        return YES;
    }else{
        XHMessage* msg=[self.messages objectAtIndex:indexPath.row];
        XHMessage* lastMsg=[self.messages objectAtIndex:indexPath.row-1];
        int interval=[msg.timestamp timeIntervalSinceDate:lastMsg.timestamp];
        if(interval>60*5){
            return YES;
        }else{
            return NO;
        }
    }
}

/**
 *  配置Cell的样式或者字体
 *
 *  @param cell      目标Cell
 *  @param indexPath 目标Cell所在位置IndexPath
 */
- (void)configureCell:(XHMessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
}

/**
 *  协议回掉是否支持用户手动滚动
 *
 *  @return 返回YES or NO
 */
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling {
    return YES;
}

-(void)didSelecteShareMenuItem:(XHShareMenuItem *)shareMenuItem atIndex:(NSInteger)index{
    [super didSelecteShareMenuItem:shareMenuItem atIndex:index];
}


@end


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
#import "Utils.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CDGroupDetailController.h"
#import "CDGroupAddMemberController.h"

@interface CDChatRoomController () <QBImagePickerControllerDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    NSMutableDictionary *_loadedData;
    CDSessionManager* sessionManager;
}


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
    if (self.type == CDMsgRoomTypeGroup) {
        self.title = [_chatGroup getTitle];
    } else {
        self.title = self.chatUser.username;
    }
    
    /**
     *  You MUST set your senderId and display name
     */
    AVUser* curUser=[AVUser currentUser];
    self.senderId = curUser.objectId;
    self.senderDisplayName = curUser.username;
    
    CGSize avatarSize=CGSizeMake(30, 30);
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = avatarSize;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = avatarSize;
    
    
    //self.showLoadEarlierMessagesHeader = YES;
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop                                                                                          target:self                                                                                          action:@selector(backPressed:)];
    
    if(self.type==CDMsgRoomTypeGroup){
        UIImage* peopleImage=[UIImage imageNamed:@"chat_menu_people"];
        UIImage* _peopleImage=[Utils imageWithImage:peopleImage scaledToSize:CGSizeMake(25, 25)];
        UIBarButtonItem* item=[[UIBarButtonItem alloc] initWithImage:_peopleImage style:UIBarButtonItemStyleDone target:self action:@selector(goChatGroupDetail:)];
        self.navigationItem.rightBarButtonItem=item;
    }
    
    //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showDetail:)];

    
    if(self.type==CDMsgRoomTypeSingle){
        [sessionManager watchPeerId:self.chatUser.objectId];
    }else{
        _group=[sessionManager joinGroupById:_chatGroup.objectId];
    }
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)dealloc{
    if(self.type==CDMsgRoomTypeSingle){
        [sessionManager unwatchPeerId:self.chatUser.objectId];
    }
}

-(void)backPressed:(id)sender{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(UIImage*)getImageByMsg:(Msg*)msg{
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

-(UIImage*)getAvatarByMsg:(Msg*)msg{
    __block UIImage* avatar=[_loadedData objectForKey:msg.fromPeerId];
    if(avatar){
        return avatar;
    }else{
        AVUser* user=[sessionManager lookupUser:msg.fromPeerId];
        SDWebImageManager* man=[SDWebImageManager sharedManager];
        AVFile* avatarFile=[user objectForKey:@"avatar"];
        [man downloadImageWithURL:[NSURL URLWithString:[avatarFile url]] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if(error){
                [Utils alertError:error];
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

-(void)keyboardDidShow:(id)sender{
    NSLog(@"show");
}

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

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

#pragma mark - Messages view delegate

- (void)messageUpdated:(NSNotification *)notification {
    NSString* convid=[CDSessionManager getConvidOfRoomType:self.type otherId:self.chatUser.objectId groupId:self.group.groupId];
    NSMutableArray *messages  = [[sessionManager getMsgsForConvid:convid] mutableCopy];
    _messages=messages;
    //UIApplication* app=[UIApplication sharedApplication];
    //app.networkActivityIndicatorVisible=YES;
    //[[self.toolbarItems objectAtIndex:0] addSubview:view];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(Msg* msg in messages){
            [self getAvatarByMsg:msg];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //app.networkActivityIndicatorVisible=NO;
            //[indicator removeFromSuperview];
            [self.collectionView reloadData];
            [self scrollToBottomAnimated:YES];
        });
    });
}

- (void)sessionUpdated:(NSNotification *)notification {
    if (self.type == CDMsgRoomTypeGroup) {
        NSString *title = @"group";
        if (self.group.groupId) {
            title = [NSString stringWithFormat:@"group:%@", self.group.groupId];
        }
        self.title = title;
    }
}

- (void)sendAttachmentWithObjectId:(NSString *)objectId{
    [sessionManager sendAttachmentWithObjectId:objectId type:CDMsgTypeImage toPeerId:self.chatUser.objectId group:self.group];
}

//  Optional delegate method
//  Required if using `JSMessagesViewTimestampPolicyCustom`
//
- (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row==0){
        return YES;
    }else{
        Msg* msg=[self.messages objectAtIndex:indexPath.row];
        Msg* lastMsg=[self.messages objectAtIndex:indexPath.row-1];
        int interval=[[msg getTimestampDate] timeIntervalSinceDate:[lastMsg getTimestampDate]];
        if(interval>60*5){
            return YES;
        }else{
            return NO;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    switch (buttonIndex) {
        case 0:
        {
            @try {
                UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
                imagePickerController.delegate = self;
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }
            @catch (NSException *exception) {
                
            }
            @finally {
                
            }
        }
            break;
        case 1:
        {
            QBImagePickerController *imagePickerController = [[QBImagePickerController alloc] init];
            imagePickerController.delegate = self;
            imagePickerController.allowsMultipleSelection = NO;
            //            imagePickerController.minimumNumberOfSelection = 3;
            
            //                [self.navigationController pushViewController:imagePickerController animated:YES];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
            [self presentViewController:navigationController animated:YES completion:^{
                
            }];

        }
            break;
        default:
            break;
    }
}

- (void)dismissImagePickerController
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popToViewController:self animated:YES];
    }
}

#pragma mark - QBImagePickerControllerDelegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAsset:(ALAsset *)asset
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    NSLog(@"*** qb_imagePickerController:didSelectAsset:");
    NSLog(@"%@", asset);
    ALAssetRepresentation *representation = [asset defaultRepresentation];
//    Byte *buffer = (Byte*)malloc((unsigned long)representation.size);
//    
//    // add error checking here
//    NSUInteger buffered = [representation getBytes:buffer fromOffset:0.0 length:(NSUInteger)representation.size error:nil];
//    NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
//
    UIImage* image=[UIImage imageWithCGImage:[representation fullResolutionImage]];
    if (image) {
        [self sendImage:image];
    }
    [self dismissImagePickerController];
    [self sendFinish];
}

-(void)sendFinish{
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [self finishSendingMessage];
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets
{
    NSLog(@"*** qb_imagePickerController:didSelectAssets:");
    NSLog(@"%@", assets);
    
    [self dismissImagePickerController];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    NSLog(@"*** qb_imagePickerControllerDidCancel:");
    
    [self dismissImagePickerController];
}

-(void)sendImage:(UIImage*)image{
    UIImage *scaledImage = [image resizedImageToFitInSize:CGSizeMake(1080, 1920) scaleIfSmaller:NO];
    NSData *imageData = UIImageJPEGRepresentation(scaledImage, 0.6);
    
    NSString* objectId=[CDSessionManager uuid];
    NSString* path=[CDSessionManager getPathByObjectId:objectId];
    NSError* error;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    NSLog(@" save path=%@",path);
    if(error==nil){
        [self sendAttachmentWithObjectId:objectId];
    }else{
        [Utils alert:@"write image to file error"];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"%s",__PRETTY_FUNCTION__);
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if (image) {
        [self sendImage:image];
    }
   [self dismissImagePickerController];
   [self sendFinish];
}

#pragma mark - Actions

-(JSQMessage*)getJSQMessageByMsg:(Msg*)msg{
    AVUser* fromUser=[sessionManager lookupUser:msg.fromPeerId];
    AVUser* curUser=[AVUser currentUser];
    JSQMessage* copyMessage;
    if(msg.type==CDMsgTypeText){
        copyMessage=[JSQTextMessage messageWithSenderId:fromUser.objectId displayName:fromUser.username text:msg.content];
    }else if(msg.type==CDMsgTypeAudio){
        copyMessage=[JSQTextMessage messageWithSenderId:fromUser.objectId displayName:fromUser.username text:@"语音"];
    }else if(msg.type==CDMsgTypeLocation){
        copyMessage=[JSQTextMessage messageWithSenderId:fromUser.objectId displayName:fromUser.username text:msg.content];
    }else{
        id<JSQMessageMediaData> messageData;
        if(msg.type==CDMsgTypeImage){
            JSQPhotoMediaItem *photoItem=[[JSQPhotoMediaItem alloc] init];
            BOOL outgoing=[curUser.objectId isEqualToString:fromUser.objectId];
            photoItem.appliesMediaViewMaskAsOutgoing=outgoing;
            photoItem.image=[self getImageByMsg:msg];
            messageData=photoItem;
        }else{
            [NSException raise:@"invalid type" format:nil];
        }
        copyMessage=[JSQMediaMessage messageWithSenderId:fromUser.objectId displayName:fromUser.username media:messageData];
    }
    return copyMessage;
}

- (void)receiveMessage
{
    /**
     *  DEMO ONLY
     *
     *  The following is simply to simulate received messages for the demo.
     *  Do not actually do this.
     */
    
    
    /**
     *  Show the typing indicator to be shown
     */
    self.showTypingIndicator = !self.showTypingIndicator;
    
    /**
     *  Scroll to actually view the indicator
     */
    [self scrollToBottomAnimated:YES];
    
    /**
     *  Copy last sent message, this will be the new "received" message
     */
    Msg* msg=[_messages lastObject];
    JSQMessage *copyMessage=[self getJSQMessageByMsg:msg];
    /**
     *  Allow typing indicator to show
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        

        JSQMessage *newMessage = nil;
        id<JSQMessageMediaData> newMediaData = nil;
        id newMediaAttachmentCopy = nil;
        
        if ([copyMessage isKindOfClass:[JSQMediaMessage class]]) {
            /**
             *  Last message was a media message
             */
            id<JSQMessageMediaData> copyMediaData = copyMessage.media;
            
            if ([copyMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                JSQPhotoMediaItem *photoItemCopy = [((JSQPhotoMediaItem *)copyMediaData) copy];
                photoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [UIImage imageWithCGImage:photoItemCopy.image.CGImage];
                
                /**
                 *  Set image to nil to simulate "downloading" the image
                 *  and show the placeholder view
                 */
                photoItemCopy.image = nil;
                
                newMediaData = photoItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                JSQLocationMediaItem *locationItemCopy = [((JSQLocationMediaItem *)copyMediaData) copy];
                locationItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [locationItemCopy.location copy];
                
                /**
                 *  Set location to nil to simulate "downloading" the location data
                 */
                locationItemCopy.location = nil;
                
                newMediaData = locationItemCopy;
            }
            else if ([copyMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                JSQVideoMediaItem *videoItemCopy = [((JSQVideoMediaItem *)copyMediaData) copy];
                videoItemCopy.appliesMediaViewMaskAsOutgoing = NO;
                newMediaAttachmentCopy = [videoItemCopy.fileURL copy];
                
                /**
                 *  Reset video item to simulate "downloading" the video
                 */
                videoItemCopy.fileURL = nil;
                videoItemCopy.isReadyToPlay = NO;
                
                newMediaData = videoItemCopy;
            }
            else {
                NSLog(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
            }
            
            newMessage = [JSQMediaMessage messageWithSenderId:copyMessage.senderId
                                                  displayName:copyMessage.senderDisplayName
                                                        media:newMediaData];
        }
        else {
            /**
             *  Last message was a text message
             */
            newMessage = [JSQTextMessage messageWithSenderId:copyMessage.senderId
                                                 displayName:copyMessage.senderDisplayName
                                                        text:copyMessage.text];
        }
        
        /**
         *  Upon receiving a message, you should:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishReceivingMessage`
         */
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        
        [self finishReceivingMessage];
        
        
        if ([newMessage isKindOfClass:[JSQMediaMessage class]]) {
            /**
             *  Simulate "downloading" media
             */
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /**
                 *  Media is "finished downloading", re-display visible cells
                 *
                 *  If media cell is not visible, the next time it is dequeued the view controller will display its new attachment data
                 *
                 *  Reload the specific item, or simply call `reloadData`
                 */
                
                if ([newMediaData isKindOfClass:[JSQPhotoMediaItem class]]) {
                    ((JSQPhotoMediaItem *)newMediaData).image = newMediaAttachmentCopy;
                    [self.collectionView reloadData];
                }
                else if ([newMediaData isKindOfClass:[JSQLocationMediaItem class]]) {
                    [((JSQLocationMediaItem *)newMediaData)setLocation:newMediaAttachmentCopy withCompletionHandler:^{
                        [self.collectionView reloadData];
                    }];
                }
                else if ([newMediaData isKindOfClass:[JSQVideoMediaItem class]]) {
                    ((JSQVideoMediaItem *)newMediaData).fileURL = newMediaAttachmentCopy;
                    ((JSQVideoMediaItem *)newMediaData).isReadyToPlay = YES;
                    [self.collectionView reloadData];
                }
                else {
                    NSLog(@"%s error: unrecognized media item", __PRETTY_FUNCTION__);
                }
                
            });
        }
        
    });
}


#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    [sessionManager sendMessageWithType:CDMsgTypeText content:text
                       toPeerId:self.chatUser.objectId group:self.group];
    
    [self finishSendingMessage];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"相册", nil];
    [actionSheet showFromToolbar:self.inputToolbar];
}

-(JSQMessage*)getJSQMessageAtPos:(NSInteger)pos{
    return [self getJSQMessageByMsg:[_messages objectAtIndex:pos]];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage* jsqMessage=[self getJSQMessageAtPos:indexPath.row];
    return jsqMessage;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self getJSQMessageAtPos:indexPath.row];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    Msg* msg=[_messages objectAtIndex:indexPath.row];
    JSQMessagesAvatarImage* avatar=[JSQMessagesAvatarImage avatarWithImage:[self getAvatarByMsg:msg]];
    return avatar;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if ([self hasTimestampForRowAtIndexPath:indexPath]) {
        Msg* msg=[_messages objectAtIndex:indexPath.row];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:[msg getTimestampDate]];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self getJSQMessageAtPos:indexPath.row];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}



- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    Msg* msg=[_messages objectAtIndex:indexPath.row];
    if([msg fromMe]){
        NSMutableAttributedString* attrString=[[NSMutableAttributedString alloc] initWithString:msg.getStatusDesc];
        return attrString;
    }else{
        return nil;
    }
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *jsqMessage = [self getJSQMessageAtPos:indexPath.row];
    
    if ([jsqMessage isKindOfClass:[JSQTextMessage class]]) {
        
        if ([jsqMessage.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }else{
        
    }
    
    return cell;
}


#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if ([self hasTimestampForRowAtIndexPath:indexPath]) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self getJSQMessageAtPos:indexPath.row];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    Msg* msg=[_messages objectAtIndex:indexPath.row];
    if(msg.fromMe){
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }else{
        return 0.0f;
    }
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma keyboard event
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.collectionView.contentInset = contentInsets;
    self.collectionView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.inputToolbar.frame.origin) ) {
        //[self.collectionView scrollRectToVisible:self.inputToolbar.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.collectionView.contentInset = contentInsets;
    self.collectionView.scrollIndicatorInsets = contentInsets;
}


@end


//
//  CDGroupDetailController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDGroupDetailController.h"
#import "CDImageLabelCollectionCell.h"
#import "UserService.h"
#import "CDSessionManager.h"
#import "Utils.h"
#import "CDChatRoomController.h"
#import "CDGroupAddMemberController.h"
#import "CDCommonDefine.h"

@interface CDGroupDetailController (){
    NSArray* groupMembers;
    CDSessionManager* sessionManager;
    BOOL own;
}
@end

@implementation CDGroupDetailController

static NSString * const reuseIdentifier = @"Cell";


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    self.title=[self.chatGroup getTitle];
    NSString* nibName=NSStringFromClass([CDImageLabelCollectionCell class]);
    NSLog(@"nibName=%@",nibName);
    [self.collectionView registerNib:[UINib nibWithNibName:nibName bundle:nil]  forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    NSString* curUserId=[AVUser currentUser].objectId;
    if([self.chatGroup.owner.objectId isEqualToString:curUserId]){
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMember)];
        own=YES;
    }else{
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"退群" style:UIBarButtonItemStylePlain target:self action:@selector(quitGroup)];
    }
    
    sessionManager=[CDSessionManager sharedInstance];
    // Do any additional setup after loading the view.
    [self initWithMemberIds:self.chatGroup.m];
    UILongPressGestureRecognizer* gestureRecognizer=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressUser:)];
    gestureRecognizer.delegate=self;
    [self.collectionView addGestureRecognizer:gestureRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshChatGroup) name:NOTIFICATION_GROUP_UPDATED object:nil];
}

-(void)quitGroup{
    [sessionManager quitFromGroup:self.chatGroup];
    [self.navigationController popToRootViewControllerAnimated:YES];
    UIViewController* first=self.navigationController.viewControllers[0];
    [first.presentingViewController dismissViewControllerAnimated:YES completion:nil];;
}

-(void)longPressUser:(UILongPressGestureRecognizer*)gestureRecognizer{
    if(gestureRecognizer.state!=UIGestureRecognizerStateBegan){
        return;
    }
    CGPoint p=[gestureRecognizer locationInView:self.collectionView];
    NSIndexPath* indexPath=[self.collectionView indexPathForItemAtPoint:p];
    if(indexPath==nil){
        NSLog(@"can't not find index path");
    }else{
        if(own){
            NSString* userId=[self.chatGroup.m objectAtIndex:indexPath.row];
            if([userId isEqualToString:self.chatGroup.owner.objectId]==NO){
                UIAlertView * alert=[[UIAlertView alloc] initWithTitle:nil message:@"确定要踢走该成员吗？"  delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
                alert.tag=indexPath.row;
                [alert show];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex==0){
        int pos=alertView.tag;
        NSString* userId=[self.chatGroup.m objectAtIndex:pos];
        [sessionManager kickMemberFromGroup:self.chatGroup userId:userId];
    }
}

-(void)initWithMemberIds:(NSArray*)userIds{
    [sessionManager cacheUsersWithIds:userIds callback:^(NSArray *objects, NSError *error) {
        [Utils filterError:error callback:^{
            groupMembers=self.chatGroup.m;
            [self.collectionView reloadData];
        }];
    }];
}

-(void)refreshChatGroup{
    [self.chatGroup fetchInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        [Utils filterError:error callback:^{
            [self initWithMemberIds:self.chatGroup.m];
        }];
    }];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:NOTIFICATION_GROUP_UPDATED object:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addMember{
    CDGroupAddMemberController *controller=[[CDGroupAddMemberController alloc] init];
    controller.chatGroup=self.chatGroup;
    [self.navigationController pushViewController:controller animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [groupMembers count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    int labelTag=1;
    int imageTag=2;
    
    NSString* userId=[groupMembers objectAtIndex:indexPath.row];
    AVUser* user=[sessionManager lookupUser:userId];
    
    UILabel* label=(UILabel*)[cell viewWithTag:labelTag];
    UIImageView* imageView=(UIImageView*)[cell viewWithTag:imageTag];
    
    [UserService displayAvatarOfUser:user avatarView:imageView];
    label.text=user.username;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(90, 90);
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* userId=[groupMembers objectAtIndex:indexPath.row];
    NSString* curUserId=[AVUser currentUser].objectId;
    if([curUserId isEqualToString:userId]==YES){
        return YES;
    }
    
    AVUser* user=[sessionManager lookupUser:userId];
    CDChatRoomController* chatController=[[CDChatRoomController alloc] init];
    chatController.type=CDMsgRoomTypeSingle;
    chatController.chatUser=user;
    
    [self.navigationController setViewControllers:[NSArray arrayWithObject:chatController] animated:YES];
    return YES;
}

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end

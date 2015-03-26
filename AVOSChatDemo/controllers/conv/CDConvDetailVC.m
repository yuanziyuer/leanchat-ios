//
//  CDGroupDetailController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDConvDetailVC.h"
#import "CDImageLabelCollectionCell.h"
#import "CDChatRoomVC.h"
#import "CDAddMemberVC.h"
#import "CDConvNameVC.h"
#import "CDService.h"

@interface CDConvDetailVC ()<UICollectionViewDelegate,UICollectionViewDataSource,
   UIGestureRecognizerDelegate,UIAlertViewDelegate,UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property CDIM* im;

@property NSArray* groupMembers;

@property BOOL own;

@property CDConvType type;

@property CDStorage* storage;

@property CDNotify* notify;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalConstraint;
@property (weak, nonatomic) IBOutlet UITableView *settingTableView;

@property UITableViewCell* nameCell;

@property UITableViewCell* deleteMsgsCell;

@property UITableViewCell* quitCell;

@end

@implementation CDConvDetailVC

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.clearsSelectionOnViewWillAppear = NO;
    
    self.view.backgroundColor=NORMAL_BACKGROUD_COLOR;
    
    NSString* nibName=NSStringFromClass([CDImageLabelCollectionCell class]);
    [self.collectionView registerNib:[UINib nibWithNibName:nibName bundle:nil]  forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    
    [_settingTableView setDataSource:self];
    [_settingTableView setDelegate:self];
    
    UILongPressGestureRecognizer* gestureRecognizer=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressUser:)];
    gestureRecognizer.delegate=self;
    [self.collectionView addGestureRecognizer:gestureRecognizer];
    
    _im=[CDIM sharedInstance];
    _notify=[CDNotify sharedInstance];
    _storage=[CDStorage sharedInstance];
    _type=[CDConvService typeOfConv:self.conv];
    [_notify addConvObserver:self selector:@selector(refresh)];
    [self refresh];
    
    _nameCell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell1"];
    _nameCell.textLabel.text=@"群聊名称";
    _nameCell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    
    _deleteMsgsCell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell2"];
    _deleteMsgsCell.textLabel.text=@"清空聊天记录";
    
    _quitCell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell3"];
    _quitCell.textLabel.text=@"删除并退出";
}

-(AVIMConversation*)conv{
    return [CDCache getCurConv];
}

-(void)refresh{
    AVIMConversation* conv=[self conv];
    NSSet* userIds=[NSSet setWithArray:conv.members];
    [CDCache cacheUsersWithIds:userIds callback:^(NSArray *objects, NSError *error) {
        [CDUtils filterError:error callback:^{
            _groupMembers=conv.members;
            [UIView animateWithDuration:0 animations:^{
                [self.collectionView reloadData];
            } completion:^(BOOL finished) {
                CGFloat h=self.collectionView.contentSize.height;
                //DLog(@"%f",h)
                if(h<CGRectGetHeight(self.view.frame)){
                    _verticalConstraint.constant=h;
                }
            }];
        }];
    }];
    NSString* curUserId=[AVUser currentUser].objectId;
    _own=[conv.creator isEqualToString:curUserId];
    [self setupBarButton];
    [_settingTableView reloadData];
    
    self.title=[NSString stringWithFormat:@"详情(%d人)",self.conv.members.count];
}

-(void)setupBarButton{
    UIBarButtonItem* addMember=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMember)];
    self.navigationItem.rightBarButtonItem=addMember;
}

-(void)quitConv{
    [self.conv quitWithCallback:^(BOOL succeeded, NSError *error) {
        if([CDUtils filterError:error]){
            [_storage deleteRoomByConvid:self.conv.conversationId];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
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
        if(_own){
            AVIMConversation* conv=[self conv];
            NSString* userId=[conv.members objectAtIndex:indexPath.row];
            if([userId isEqualToString:conv.creator]==NO){
                UIAlertView * alert=[[UIAlertView alloc]
                                     initWithTitle:nil message:@"确定要踢走该成员吗？"  delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
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
        NSString* userId=[self.conv.members objectAtIndex:pos];
        [self.conv removeMembersWithClientIds:@[userId] callback:^(BOOL succeeded, NSError *error) {
            if([CDUtils filterError:error]){
                [CDCache refreshCurConv:^(BOOL succeeded, NSError *error) {
                    if([CDUtils filterError:error]){
                    }
                }];
            }
        }];
    }
}

-(void)dealloc{
    [_notify removeConvObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addMember{
    CDAddMemberVC *controller=[[CDAddMemberVC alloc] init];;
    controller.groupDetailVC=self;
    UINavigationController* nav=[[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
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
    return [_groupMembers count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    int labelTag=1;
    int imageTag=2;
    
    NSString* userId=[_groupMembers objectAtIndex:indexPath.row];
    AVUser* user=[CDCache lookupUser:userId];
    UILabel* label=(UILabel*)[cell viewWithTag:labelTag];
    UIImageView* imageView=(UIImageView*)[cell viewWithTag:imageTag];
    
    [CDUserService displayAvatarOfUser:user avatarView:imageView];
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
    NSString* userId=[_groupMembers objectAtIndex:indexPath.row];
    NSString* curUserId=[AVUser currentUser].objectId;
    if([curUserId isEqualToString:userId]==YES){
        return YES;
    }
    
    AVUser* user=[CDCache lookupUser:userId];
    [_im fetchConvWithUserId:user.objectId callback:^(AVIMConversation *conversation, NSError *error) {
        if([CDUtils filterError:error]){
            UINavigationController* nav=self.navigationController;
            [nav popToRootViewControllerAnimated:YES];
            [CDChatRoomVC goWithConv:conversation fromNav:nav];
        }
    }];
    return YES;
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(_type==CDConvTypeGroup){
        return 3;
    }else{
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell;
    if(_type==CDConvTypeGroup){
        switch (indexPath.section) {
            case 0:
                return _nameCell;
            case 1:
                return _deleteMsgsCell;
            case 2:
                return _quitCell;
            default:
                break;
        }
    }else{
        switch (indexPath.section) {
            case 0:
                return _deleteMsgsCell;
                break;
            default:
                break;
        }
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 10;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 10;
}

-(void)deleteMsgs{
    [_storage deleteMsgsByConvid:self.conv.conversationId];
    [CDUtils alert:@"已清空"];
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(_type==CDConvTypeGroup){
        switch (indexPath.section) {
            case 0:{
                   CDConvNameVC* vc=[[CDConvNameVC alloc] init];
                   vc.detailVC=self;
                   vc.conv=self.conv;
                   UINavigationController* nav=[[UINavigationController alloc] initWithRootViewController:vc];
                   [self.navigationController presentViewController:nav animated:YES completion:nil];
                }
                break;
            case 1:
                [self deleteMsgs];
                break;
            case 2:
                [self quitConv];
                break;
        }
    }else{
        if(indexPath.section==0){
            [self deleteMsgs];
        }
    }
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

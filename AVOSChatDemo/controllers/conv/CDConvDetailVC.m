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

@property (weak, nonatomic) IBOutlet UITableView *settingTableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;

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
    _storage=[CDStorage sharedInstance];
    _type=[CDConvService typeOfConv:self.conv];
    
    [self refresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:NOTIFICATION_GROUP_UPDATED object:nil];
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
                _heightConstraint.constant=h+self.navigationController.navigationBar.frame.size.height;
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
            UIViewController* first=self.navigationController.viewControllers[0];
            [first.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
                        [self refresh];
                    }
                }];
            }
        }];
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:NOTIFICATION_GROUP_UPDATED object:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addMember{
    CDAddMemberVC *controller=[[CDAddMemberVC alloc] init];;
    controller.groupDetailVC=self;
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
            CDChatRoomVC* vc=[[CDChatRoomVC alloc] initWithConv:conversation];
            [self.navigationController setViewControllers:[NSArray arrayWithObject:vc] animated:YES];
        }
    }];
    return YES;
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(_type==CDConvTypeGroup){
        return 2;
    }else{
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell;
    if(indexPath.section==0){
        cell=[tableView dequeueReusableCellWithIdentifier:@"cell1"];
        if(cell==nil){
            cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell1"];
            cell.textLabel.text=@"群聊名称";
            cell.detailTextLabel.text=[CDConvService nameOfConv:self.conv];
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        }
    }else if(indexPath.section==1){
        cell=[tableView dequeueReusableCellWithIdentifier:@"cell2"];
        if(cell==nil){
            cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell2"];
            cell.textLabel.text=@"删除并退出";
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    return cell;
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section==0){
        CDConvNameVC* vc=[[CDConvNameVC alloc] init];
        vc.detailVC=self;
        vc.conv=self.conv;
        [self.navigationController pushViewController:vc animated:YES];
    }else if(indexPath.section==1){
        [self quitConv];
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

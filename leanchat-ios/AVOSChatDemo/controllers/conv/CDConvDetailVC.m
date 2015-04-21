//
//  CDGroupDetailController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/6.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDConvDetailVC.h"
#import "CDAddMemberVC.h"
#import "CDUserInfoVC.h"
#import "CDConvNameVC.h"
#import "CDService.h"
#import "CDConvDetailMembersCell.h"

@interface CDConvDetailVC ()<UIGestureRecognizerDelegate,UIAlertViewDelegate,UITableViewDelegate,UITableViewDataSource,CDConvDetailMembersHeaderViewDelegate>


@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic,strong) CDConvDetailMembersCell *membersCell;

@property CDIM* im;

@property BOOL own;

@property CDConvType type;

@property CDStorage* storage;

@property CDNotify* notify;

@property (nonatomic,strong) UITableViewCell* nameCell;

@property (nonatomic,strong) UITableViewCell* deleteMsgsCell;

@property (nonatomic,strong) UITableViewCell* quitCell;

@property (nonatomic,strong) AVUser *longPressedMember;

@property (nonatomic,strong) NSArray* members;

@end

@implementation CDConvDetailVC

static NSString * const reuseIdentifier = @"Cell";

- (instancetype)init
{
    self = [super init];
    if (self) {
        _im=[CDIM sharedInstance];
        _notify=[CDNotify sharedInstance];
        _storage=[CDStorage sharedInstance];
        _type=self.conv.type;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.clearsSelectionOnViewWillAppear = NO;
    
    self.view.backgroundColor=NORMAL_BACKGROUD_COLOR;
    [_notify addConvObserver:self selector:@selector(refresh)];
    [self refresh];
}

-(CDConvDetailMembersCell*)membersCell{
    if(_membersCell==nil){
        _membersCell=[[CDConvDetailMembersCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[CDConvDetailMembersCell reuseIdentifier]];
        _membersCell.membersCellDelegate=self;
    }
    return _membersCell;
}

-(UITableViewCell*)nameCell{
    if(_nameCell==nil){
        _nameCell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell1"];
        _nameCell.textLabel.text=@"群聊名称";
        _nameCell.detailTextLabel.text=self.conv.displayName;
        _nameCell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    }
    return _nameCell;
}

-(UITableViewCell*)deleteMsgsCell{
    if(_deleteMsgsCell==nil){
        _deleteMsgsCell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell2"];
        _deleteMsgsCell.textLabel.text=@"清空聊天记录";
    }
    return _deleteMsgsCell;
}

-(UITableViewCell*)quitCell{
    if(_quitCell==nil){
        _quitCell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell3"];
        _quitCell.textLabel.text=@"删除并退出";
    }
    return _quitCell;
}

-(AVIMConversation*)conv{
    return [CDCache getCurConv];
}

-(void)refresh{
    AVIMConversation* conv=[self conv];
    NSSet* userIds=[NSSet setWithArray:conv.members];
    WEAKSELF
    NSString* curUserId=[AVUser currentUser].objectId;
    _own=[conv.creator isEqualToString:curUserId];
    [self setupBarButton];
    self.title=[NSString stringWithFormat:@"详情(%ld人)",(long)self.conv.members.count];
    [CDCache cacheUsersWithIds:userIds callback:^(BOOL succeeded, NSError *error) {
        [CDUtils filterError:error callback:^{
            NSMutableArray *memberUsers=[NSMutableArray array];
            for(NSString* userId in userIds){
                [memberUsers addObject:[CDCache lookupUser:userId]];
            }
            weakSelf.members=memberUsers;
            weakSelf.membersCell.members=memberUsers;
            [weakSelf.tableView reloadData];
        }];
    }];
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
        DLog(@"can't not find index path");
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

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(_type==CDConvTypeGroup){
        return 4;
    }else{
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(_type==CDConvTypeGroup){
        switch (indexPath.section) {
            case 0:
                return self.membersCell;
            case 1:
                return self.nameCell;
            case 2:
                return self.deleteMsgsCell;
            case 3:
                return self.quitCell;
            default:
                break;
        }
    }else{
        switch (indexPath.section) {
            case 0:
                return self.membersCell;
            case 1:
                return self.deleteMsgsCell;
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
    if(indexPath.section==0){
        return [CDConvDetailMembersCell heightForMembers:self.members];
    }else{
        return 44;
    }
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
            case 1:{
                CDConvNameVC* vc=[[CDConvNameVC alloc] init];
                vc.detailVC=self;
                vc.conv=self.conv;
                UINavigationController* nav=[[UINavigationController alloc] initWithRootViewController:vc];
                [self.navigationController presentViewController:nav animated:YES completion:nil];
            }
                break;
            case 2:
                [self deleteMsgs];
                break;
            case 3:
                [self quitConv];
                break;
        }
    }else{
        if(indexPath.section==1){
            [self deleteMsgs];
        }
    }
}

-(void)didLongPressMember:(AVUser *)member{
    if(_own){
        AVIMConversation* conv=[self conv];
        if([member.objectId isEqualToString:conv.creator]==NO){
            UIAlertView * alert=[[UIAlertView alloc]
                                 initWithTitle:nil message:@"确定要踢走该成员吗？"  delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
            self.longPressedMember=member;
            [alert show];
        }
    }
}


- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex==0){
        WEAKSELF
        [self.conv removeMembersWithClientIds:@[self.longPressedMember.objectId] callback:^(BOOL succeeded, NSError *error) {
            weakSelf.longPressedMember=nil;
            if([CDUtils filterError:error]){
                [CDCache refreshCurConv:^(BOOL succeeded, NSError *error) {
                    if([CDUtils filterError:error]){
                    }
                }];
            }
        }];
    }
}

-(void)didSelectMember:(AVUser *)member{
    NSString* curUserId=[AVUser currentUser].objectId;
    if([curUserId isEqualToString:member.objectId]==YES){
        return ;
    }
    CDUserInfoVC* userInfoVC=[[CDUserInfoVC alloc] initWithUser:member];
    [self.navigationController pushViewController:userInfoVC animated:YES];
}


@end

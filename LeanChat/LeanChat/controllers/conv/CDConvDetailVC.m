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
#import "CDBaseNavC.h"
#import "CDConvNameVC.h"
#import "CDConvDetailMembersCell.h"
#import "CDConvReportAbuseVC.h"
#import "CDCache.h"
#import "LZAlertViewHelper.h"

static NSString *kCDConvDetailVCTitleKey = @"title";
static NSString *kCDConvDetailVCDisclosureKey = @"disclosure";
static NSString *kCDConvDetailVCDetailKey = @"detail";
static NSString *kCDConvDetailVCSelectorKey = @"selector";
static NSString *kCDConvDetailVCSwitchKey = @"switch";

@interface CDConvDetailVC () <UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, CDConvDetailMembersHeaderViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) CDConvDetailMembersCell *membersCell;

@property (nonatomic, strong) CDIM *im;

@property (nonatomic, assign) BOOL own;

@property (nonatomic, assign) CDConvType type;

@property (nonatomic, strong) CDStorage *storage;

@property (nonatomic, strong) CDNotify *notify;

@property (nonatomic, strong) NSArray *members;

@property (nonatomic, strong) UITableViewCell *switchCell;

@property (nonatomic, strong) UISwitch *muteSwitch;

@property (nonatomic, strong) LZAlertViewHelper *alertViewHelper;

@end

@implementation CDConvDetailVC

static NSString *const reuseIdentifier = @"Cell";

- (instancetype)init {
    self = [super init];
    if (self) {
        _im = [CDIM sharedInstance];
        _notify = [CDNotify sharedInstance];
        _storage = [CDStorage sharedInstance];
        _type = self.conv.type;
        self.tableViewStyle = UITableViewStyleGrouped;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_notify addConvObserver:self selector:@selector(refresh)];
    [self setupDatasource];
    [self setupBarButton];
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)setupDatasource {
    NSDictionary *dict1 = @{ kCDConvDetailVCTitleKey:@"清空聊天记录",
                             kCDConvDetailVCSelectorKey:NSStringFromSelector(@selector(deleteMsgs)) };
    NSDictionary *dict2 = @{ kCDConvDetailVCTitleKey:@"举报",
                             kCDConvDetailVCDisclosureKey:@YES,
                             kCDConvDetailVCSelectorKey:NSStringFromSelector(@selector(goReportAbuse)) };
    NSDictionary *dict3 = @{ kCDConvDetailVCTitleKey:@"消息免打扰", kCDConvDetailVCSwitchKey:@YES };
    if (_type == CDConvTypeGroup) {
        self.dataSource = [@[@{ kCDConvDetailVCTitleKey:@"群聊名称",
                                kCDConvDetailVCDisclosureKey:@YES,
                                kCDConvDetailVCDetailKey:self.conv.displayName,
                                kCDConvDetailVCSelectorKey:NSStringFromSelector(@selector(goChangeName)) },
                             dict3, dict1, dict2,
                             @{ kCDConvDetailVCTitleKey:@"删除并退出",
                                kCDConvDetailVCSelectorKey:NSStringFromSelector(@selector(quitConv)) }] mutableCopy];
    }
    else {
        self.dataSource = [@[dict3, dict1, dict2] mutableCopy];
    }
}

#pragma mark - Propertys

- (CDConvDetailMembersCell *)membersCell {
    if (_membersCell == nil) {
        _membersCell = [[CDConvDetailMembersCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[CDConvDetailMembersCell reuseIdentifier]];
        _membersCell.membersCellDelegate = self;
    }
    return _membersCell;
}

- (UISwitch *)muteSwitch {
    if (_muteSwitch == nil) {
        _muteSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [_muteSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_muteSwitch setOn:self.conv.muted];
    }
    return _muteSwitch;
}

- (AVIMConversation *)conv {
    return [CDCache getCurConv];
}

- (LZAlertViewHelper *)alertViewHelper {
    if (_alertViewHelper == nil) {
        _alertViewHelper = [[LZAlertViewHelper alloc] init];
    }
    return _alertViewHelper;
}

#pragma mark

- (void)refresh {
    AVIMConversation *conv = [self conv];
    NSSet *userIds = [NSSet setWithArray:conv.members];
    WEAKSELF
    NSString *curUserId = [AVUser currentUser].objectId;
    _own = [conv.creator isEqualToString:curUserId];
    self.title = [NSString stringWithFormat:@"详情(%ld人)", (long)self.conv.members.count];
    [CDCache cacheUsersWithIds:userIds callback: ^(BOOL succeeded, NSError *error) {
        if ([self filterError:error]) {
            NSMutableArray *memberUsers = [NSMutableArray array];
            for (NSString *userId in userIds) {
                [memberUsers addObject:[CDCache lookupUser:userId]];
            }
            weakSelf.members = memberUsers;
            weakSelf.membersCell.members = memberUsers;
            [weakSelf.tableView reloadData];
        }
    }];
}

- (void)setupBarButton {
    UIBarButtonItem *addMember = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMember)];
    self.navigationItem.rightBarButtonItem = addMember;
}

- (void)dealloc {
    [_notify removeConvObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    else {
        return self.dataSource.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        CDConvDetailMembersCell *membersCell = [tableView dequeueReusableCellWithIdentifier:[CDConvDetailMembersCell reuseIdentifier]];
        if (membersCell == nil) {
            membersCell = self.membersCell;
        }
        return membersCell;
    }
    else {
        UITableViewCell *cell;
        static NSString *identifier = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        }
        
        NSDictionary *data = self.dataSource[indexPath.row];
        NSString *title = [data objectForKey:kCDConvDetailVCTitleKey];
        cell.textLabel.text = title;
        NSString *detail = [data objectForKey:kCDConvDetailVCDetailKey];
        if (detail) {
            cell.detailTextLabel.text = self.conv.displayName;
        }
        else {
            cell.detailTextLabel.text = nil;
        }
        BOOL disclosure = [[data objectForKey:kCDConvDetailVCDisclosureKey] boolValue];
        if (disclosure) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        BOOL isSwitch = [[data objectForKey:kCDConvDetailVCSwitchKey] boolValue];
        if (isSwitch) {
            cell.accessoryView = self.muteSwitch;
        } else {
            cell.accessoryView = nil;
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return [CDConvDetailMembersCell heightForMembers:self.members];
    }
    else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        return;
    }
    NSString *selectorName = [[self.dataSource objectAtIndex:indexPath.row] objectForKey:kCDConvDetailVCSelectorKey];
    if (selectorName) {
        [self performSelector:NSSelectorFromString(selectorName) withObject:nil afterDelay:0];
    }
}

#pragma mark - member cell delegate

- (void)didSelectMember:(AVUser *)member {
    NSString *curUserId = [AVUser currentUser].objectId;
    if ([curUserId isEqualToString:member.objectId] == YES) {
        return;
    }
    CDUserInfoVC *userInfoVC = [[CDUserInfoVC alloc] initWithUser:member];
    [self.navigationController pushViewController:userInfoVC animated:YES];
}

- (void)didLongPressMember:(AVUser *)member {
    AVIMConversation *conv = [self conv];
    if ([member.objectId isEqualToString:conv.creator] == NO) {
        [self.alertViewHelper showAlertViewWithMessage:@"确定要踢走该成员吗？" block:^(BOOL confirm, NSString *text) {
            if (confirm) {
                [self.conv removeMembersWithClientIds : @[member.objectId] callback : ^(BOOL succeeded, NSError *error) {
                    if ([self filterError:error]) {
                        [CDCache refreshCurConv: ^(BOOL succeeded, NSError *error) {
                            [self alertError:error];
                        }];
                    }
                }];
            }
        }];
    }
}

#pragma mark - Action

- (void)goReportAbuse {
    CDConvReportAbuseVC *reportAbuseVC = [[CDConvReportAbuseVC alloc] initWithConvid:self.conv.conversationId];
    [self.navigationController pushViewController:reportAbuseVC animated:YES];
}

- (void)switchValueChanged:(UISwitch *)theSwitch {
    AVBooleanResultBlock block = ^(BOOL succeeded, NSError *error) {
        [self alertError:error];
    };
    if ([theSwitch isOn]) {
        [self.conv muteWithCallback:block];
    }
    else {
        [self.conv unmuteWithCallback:block];
    }
}

- (void)deleteMsgs {
    [_storage deleteMsgsByConvid:self.conv.conversationId];
    [self alert:@"已清空"];
}

- (void)goChangeName {
    CDConvNameVC *vc = [[CDConvNameVC alloc] init];
    vc.detailVC = self;
    vc.conv = self.conv;
    CDBaseNavC *nav = [[CDBaseNavC alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)addMember {
    CDAddMemberVC *controller = [[CDAddMemberVC alloc] init];
    controller.groupDetailVC = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)quitConv {
    [self.conv quitWithCallback: ^(BOOL succeeded, NSError *error) {
        if ([self filterError:error]) {
            [_storage deleteRoomByConvid:self.conv.conversationId];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

@end

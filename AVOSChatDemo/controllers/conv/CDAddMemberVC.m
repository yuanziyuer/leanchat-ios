//
//  CDGroupAddMemberController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/7.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDAddMemberVC.h"
#import "CDImageLabelTableCell.h"
#import "CDService.h"
#import "CDChatRoomVC.h"

@interface CDAddMemberVC ()

@property NSMutableArray *selected;

@property NSMutableArray *potentialIds;

@property CDIM* im;

@end

@implementation CDAddMemberVC

static NSString* reuseIdentifier=@"Cell";

- (instancetype)init
{
    self = [super init];
    if (self) {
        _selected=[NSMutableArray array];
        _potentialIds=[NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* nibName=NSStringFromClass([CDImageLabelTableCell class]);
    UINib* nib=[UINib nibWithNibName:nibName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
    
    self.title=@"邀请好友";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(invite)];
    
    _im=[CDIM sharedInstance];
    [self initPotentialIds];
    int count=_potentialIds.count;
    for(int i=0;i<count;i++){
        [_selected addObject:[NSNumber numberWithBool:NO]];
    }
}

-(void)initPotentialIds{
    [_potentialIds removeAllObjects];
    for(AVUser* user in [CDCache getFriends]){
        if([[CDCache getCurConv].members containsObject:user.objectId]==NO){
            [_potentialIds addObject:user.objectId];
        }
    }
}

-(void)invite{
    NSMutableArray* inviteIds=[[NSMutableArray alloc] init];
    for(int i=0;i<_selected.count;i++){
        if([_selected[i] boolValue]){
            [inviteIds addObject:[_potentialIds objectAtIndex:i]];
        }
    }
    AVIMConversation* conv=[CDCache getCurConv];
    if([CDConvService typeOfConv:[CDCache getCurConv]]==CDConvTypeSingle){
        NSMutableArray* members=[conv.members mutableCopy];
        [members addObjectsFromArray:inviteIds];
        [CDUtils showNetworkIndicator];
        [_im createConvWithUserIds:members callback:^(AVIMConversation *conversation, NSError *error) {
            [CDUtils hideNetworkIndicator];
            if([CDUtils filterError:error]){
                CDChatRoomVC* vc=[[CDChatRoomVC alloc] initWithConv:conversation];
                [self.navigationController setViewControllers:[NSArray arrayWithObject:vc] animated:YES];
            }
        }];
    }else{
        [CDUtils showNetworkIndicator];
        [conv addMembersWithClientIds:inviteIds callback:^(BOOL succeeded, NSError *error) {
            if(error){
                [CDUtils hideNetworkIndicator];
                [CDUtils alertError:error];
            }else{
                [CDCache refreshCurConv:^(BOOL succeeded, NSError *error) {
                    [CDUtils hideNetworkIndicator];
                    if([CDUtils filterError:error]){
                        [_groupDetailVC refresh];
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _potentialIds.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    if(cell==nil){
        cell=[[CDImageLabelTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    NSString* userId=[_potentialIds objectAtIndex:indexPath.row];
    AVUser* user=[CDCache lookupUser:userId];
    [CDUserService displayAvatarOfUser:user avatarView:cell.myImageView];
    cell.myLabel.text=user.username;
    if([_selected[indexPath.row] boolValue]){
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType=UITableViewCellAccessoryNone;
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int pos=indexPath.row;
    _selected[pos]=[NSNumber numberWithBool:![_selected[pos] boolValue]];
    [self.tableView reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

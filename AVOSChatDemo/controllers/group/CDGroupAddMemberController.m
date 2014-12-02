//
//  CDGroupAddMemberController.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/7.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDGroupAddMemberController.h"
#import "CDImageLabelTableCell.h"
#import "CDSessionManager.h"
#import "CDUserService.h"
#import "CDCacheService.h"
#import "CDUtils.h"
#import "CDGroupService.h"

@interface CDGroupAddMemberController (){
    CDSessionManager *sessionManager;
    NSMutableArray *selected;
    NSMutableArray *potentialIds;
}
@end

@implementation CDGroupAddMemberController

static NSString* reuseIdentifier=@"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    sessionManager=[CDSessionManager sharedInstance];
    
    NSString* nibName=NSStringFromClass([CDImageLabelTableCell class]);
    UINib* nib=[UINib nibWithNibName:nibName bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
    self.title=@"邀请好友";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(invite)];
    
    [self initPotentialIds];
    int count=potentialIds.count;
    selected = [[NSMutableArray alloc] init];
    for(int i=0;i<count;i++){
        [selected addObject:[NSNumber numberWithBool:NO]];
    }
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)initPotentialIds{
    potentialIds=[[NSMutableArray alloc] init];
    for(AVUser* user in [sessionManager friends]){
        if([[CDCacheService getCurrentChatGroup].m containsObject:user.objectId]==NO){
            [potentialIds addObject:user.objectId];
        }
    }
}

-(void)invite{
    NSMutableArray* inviteIds=[[NSMutableArray alloc] init];
    for(int i=0;i<selected.count;i++){
        if([selected[i] boolValue]){
            [inviteIds addObject:[potentialIds objectAtIndex:i]];
        }
    }
    UIActivityIndicatorView* indicator=[CDUtils showIndicatorAtView:self.view];
    [self inviteMembers:inviteIds callback:^(BOOL succeeded, NSError *error) {
        [indicator stopAnimating];
        [CDUtils filterError:error callback:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }];
}

-(void)inviteMembers:(NSArray*)inviteIds callback:(AVBooleanResultBlock)callback{
    [CDGroupService inviteMembersToGroup:[CDCacheService getCurrentChatGroup] userIds:inviteIds callback:^(NSArray *objects, NSError *error) {
        if(error){
            callback(NO,error);
        }else{
            [CDCacheService refreshCurrentChatGroup:callback];
        }
    }];
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
    return potentialIds.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    if(cell==nil){
        cell=[[CDImageLabelTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    NSString* userId=[potentialIds objectAtIndex:indexPath.row];
    AVUser* user=[CDCacheService lookupUser:userId];
    [CDUserService displayAvatarOfUser:user avatarView:cell.myImageView];
    cell.myLabel.text=user.username;
    if([selected[indexPath.row] boolValue]){
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
    selected[pos]=[NSNumber numberWithBool:![selected[pos] boolValue]];
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

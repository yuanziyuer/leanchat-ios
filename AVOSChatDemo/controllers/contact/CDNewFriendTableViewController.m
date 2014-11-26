//
//  CDNewFriendTableViewController.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-23.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDNewFriendTableViewController.h"
#import "CDAddRequestService.h"
#import "CDLabelButtonTableCell.h"
#import "CDCloudService.h"
#import "CDUtils.h"
#import "CDUtils.h"
#import "CDContactListController.h"

@interface CDNewFriendTableViewController (){
    NSArray *addRequests;
}
@end

@implementation CDNewFriendTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //[self.tableView setDataSource:self];
    //[self.tableView setDelegate:self];
    self.title=@"新的朋友";
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refresh];
}

-(void)refresh{
    UIActivityIndicatorView* indicator=[CDUtils showIndicatorAtView:self.view];
    [CDAddRequestService findAddRequestsWtihCallback:^(NSArray *objects, NSError *error) {
        [indicator stopAnimating];
        [CDUtils filterError:error callback:^{
            addRequests=objects;
            [self.tableView reloadData];
        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return addRequests.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static BOOL isRegNib=NO;
    if(!isRegNib){
        [tableView registerNib:[UINib nibWithNibName:@"CDLabelButtonTableCell" bundle:nil]forCellReuseIdentifier:@"cell"];
    }
    CDLabelButtonTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell" ];
    CDAddRequest* addRequest=[addRequests objectAtIndex:indexPath.row];
    cell.nameLabel.text=addRequest.fromUser.username;
    if(addRequest.status==kAddRequestStatusWait){
        cell.actionBtn.enabled=true;
        cell.actionBtn.tag=indexPath.row;
        [cell.actionBtn setTitle:@"同意" forState:UIControlStateNormal];
        [cell.actionBtn addTarget:self action:@selector(actionBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        cell.actionBtn.enabled=false;
        [cell.actionBtn setTitle:@"已同意" forState:UIControlStateNormal];
    }
    // Configure the cell...
//    UITableViewCell* cell1=[[UITableViewCell alloc] init];
//    cell1.textLabel.text=@"hah";
    return cell;
}

-(void)actionBtnClicked:(id)sender{
    UIButton *btn=(UIButton*)sender;
    CDAddRequest* addRequest=[addRequests objectAtIndex:btn.tag];
    [CDCloudService agreeAddRequestWithId:addRequest.objectId callback:^(id object, NSError *error) {
        if(error){
            [CDUtils alert:[error localizedDescription]];
        }else{
            [CDUtils alert:@"添加成功"];
            [self refresh];
            [[NSNotificationCenter defaultCenter] postNotificationName:CD_FRIENDS_UPDATE object:nil];
        }
    }];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

@end

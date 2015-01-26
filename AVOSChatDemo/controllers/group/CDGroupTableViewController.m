//
//  CDGroupTableViewController.m
//  
//
//  Created by lzw on 14/11/6.
//
//

#import "CDGroupTableViewController.h"
#import "CDChatGroup.h"
#import "CDGroupService.h"
#import "CDChatRoomController.h"
#import "CDNewGroupViewController.h"
#import "CDImageLabelTableCell.h"
#import "CDCacheService.h"
#import "CDUtils.h"

@interface CDGroupTableViewController (){
    NSArray* convs;
    UIImage * groupImage;
    id groupUpdatedObserver;
    CDIM* _im;
}
@end

static NSString* cellIndentifier=@"cell";

@implementation CDGroupTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    convs=[[NSMutableArray alloc] init];
    _im=[CDIM sharedInstance];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title=@"群组";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(goNewGroup)];
    NSString* nibName=NSStringFromClass([CDImageLabelTableCell class]);
    UINib* nib=[UINib nibWithNibName:nibName bundle:nil];;
    [self.tableView registerNib:nib forCellReuseIdentifier:cellIndentifier];
    groupImage=[UIImage imageNamed:@"group_icon"];
    [self refresh:nil];
    
    UIRefreshControl* refreshControl=[[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl=refreshControl;
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    groupUpdatedObserver=[[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_GROUP_UPDATED object:nil queue:mainQueue usingBlock:^(NSNotification *note) {
        [self refresh:nil];
    }];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:groupUpdatedObserver];
}

-(void)refresh:(UIRefreshControl*)refreshControl{
    [_im findGroupedConvsWithBlock:^(NSArray *objects, NSError *error) {
        [CDUtils stopRefreshControl:refreshControl];
        convs=objects;
        [self.tableView reloadData];
    }];
//    [CDGroupService findGroupsWithCallback:^(NSArray *objects, NSError *error) {
//    } cacheFirst:NO];
}

-(void)goNewGroup{
    CDNewGroupViewController* controller=[[CDNewGroupViewController alloc] init];
    UINavigationController*nav =[[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return convs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(cell==nil){
        cell=[[CDImageLabelTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    AVIMConversation* conv=[convs objectAtIndex:indexPath.row];
    cell.myLabel.text=conv.name;
    [cell.myImageView setImage:groupImage];
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
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
    CDChatGroup* chatGroup=[convs objectAtIndex:indexPath.row];
    CDChatRoomController * controlloer=[[CDChatRoomController alloc] init];
    [CDCacheService setCurrentConversation:chatGroup];
    UINavigationController* nav=[[UINavigationController alloc] initWithRootViewController:controlloer];
    [self presentViewController:nav animated:YES completion:nil];
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

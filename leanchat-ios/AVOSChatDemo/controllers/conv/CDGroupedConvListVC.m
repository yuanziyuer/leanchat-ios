//
//  CDGroupTableViewController.m
//  
//
//  Created by lzw on 14/11/6.
//
//

#import "CDGroupedConvListVC.h"
#import "CDConvCreateVC.h"
#import "CDIMService.h"
#import "CDUtils.h"
#import "CDImageLabelTableCell.h"

@interface CDGroupedConvListVC (){
    NSArray* convs;
    id groupUpdatedObserver;
    CDIM* _im;
}

@property  CDNotify* notify;

@end

static NSString* cellIndentifier=@"cell";

@implementation CDGroupedConvListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    convs=[[NSMutableArray alloc] init];
    _im=[CDIM sharedInstance];
    _notify=[CDNotify sharedInstance];
    self.title=@"群组";
//    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(goNewGroup)];
    NSString* nibName=NSStringFromClass([CDImageLabelTableCell class]);
    UINib* nib=[UINib nibWithNibName:nibName bundle:nil];;
    [self.tableView registerNib:nib forCellReuseIdentifier:cellIndentifier];
    [self refresh:nil];
    
    UIRefreshControl* refreshControl=[[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl=refreshControl;
    
    [_notify addConvObserver:self selector:@selector(refresh:)];
}

-(void)dealloc{
    [_notify removeConvObserver:self];
}

-(void)refresh:(UIRefreshControl*)refreshControl{
    [_im findGroupedConvsWithBlock:^(NSArray *objects, NSError *error) {
        [CDUtils stopRefreshControl:refreshControl];
        convs=objects;
        [self.tableView reloadData];
    }];
}

-(void)goNewGroup{
    CDConvCreateVC* controller=[[CDConvCreateVC alloc] init];
    UINavigationController*nav =[[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return convs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CDImageLabelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(cell==nil){
        cell=[[CDImageLabelTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    AVIMConversation* conv=[convs objectAtIndex:indexPath.row];
    cell.myLabel.text=conv.title;
    [cell.myImageView setImage:conv.icon];
    return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AVIMConversation* conv=[convs objectAtIndex:indexPath.row];
    [[CDIMService shareInstance] goWithConv:conv fromNav:self.navigationController];
}

@end

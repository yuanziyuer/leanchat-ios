//
//  CDConvNameVC.m
//  LeanChat
//
//  Created by lzw on 15/2/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDConvNameVC.h"
#import "CDService.h"

@interface CDConvNameVC ()

@property (strong, nonatomic) IBOutlet UITableViewCell *tableCell;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@property CDIM* im;

@property CDNotify* notify;

@end

@implementation CDConvNameVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title=@"群聊名称";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveName:)];
    self.nameTextField.text=_conv.name;
    _im=[CDIM sharedInstance];
    _notify=[CDNotify sharedInstance]; 
}

-(void)saveName:(id)sender{
    if(_nameTextField.text.length>0){
         [_im updateConv:_conv name:_nameTextField.text attrs:nil callback:^(BOOL succeeded, NSError *error) {
             if([CDUtils filterError:error]){
                 [_notify postConvNotify];
                 [self.navigationController popViewControllerAnimated:YES];
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _tableCell;
}


@end

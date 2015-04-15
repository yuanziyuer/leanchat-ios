//
//  CDBaseController.m
//  AVOSChatDemo
//
//  Created by Qihe Bian on 7/24/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "CDBaseVC.h"

@interface UIViewController ()

- (CGRect)_defaultInitialViewFrame;

@end

@implementation CDBaseVC

- (void)loadView {
    [super loadView];
    self.view =  [[UIScrollView alloc] initWithFrame:self.view.frame];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

@end

//
//  MCProfileNameVC.m
//  ClassNet
//
//  Created by lzw on 15/4/6.
//  Copyright (c) 2015年 lzw. All rights reserved.
//

#import "CDProfileNameVC.h"

@interface MCNameForm : NSObject <FXForm>

@property (nonatomic, strong) NSString *name;

@end

@implementation MCNameForm

- (NSArray *)fields {
    return @[@{ FXFormFieldKey:@"name", FXFormFieldTitle:@"姓名" }];
}

- (NSArray *)extraFields {
    return @[@{ FXFormFieldTitle:@"保存", FXFormFieldHeader:@"", FXFormFieldAction:@"onSaveCellClick:" }];
}

@end


@interface CDProfileNameVC ()

@end


@implementation CDProfileNameVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"修改姓名";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    MCNameForm *nameForm = [[MCNameForm alloc] init];
    nameForm.name = self.placeholderName;
    self.formController.form = nameForm;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)onSaveCellClick:(UITableViewCell <FXFormFieldCell> *)sender {
    MCNameForm *nameForm = sender.field.form;
    if ([nameForm.name isEqualToString:self.placeholderName]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        if (nameForm.name.length > 0) {
            [self.navigationController popViewControllerAnimated:YES];
            if ([self.profileNameVCDelegate respondsToSelector:@selector(didDismissProfileNameVCWithNewName:)]) {
                [self.profileNameVCDelegate didDismissProfileNameVCWithNewName:nameForm.name];
            }
        }
    }
}

@end

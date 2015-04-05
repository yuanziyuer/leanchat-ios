//
//  CDImageLabelTableCell.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/5.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDImageLabelTableCell.h"
#import "CDUtils.h"

@implementation CDImageLabelTableCell

- (void)awakeFromNib {
    // Initialization code
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

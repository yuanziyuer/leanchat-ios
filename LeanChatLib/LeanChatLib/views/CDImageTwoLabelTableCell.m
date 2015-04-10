//
//  CDImageTwoLabelTableCell.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/11.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDImageTwoLabelTableCell.h"

@implementation CDImageTwoLabelTableCell

-(instancetype)init{
    self=[self init];
    if(self){
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    if (_unreadCount > 0) {
        [self.unreadBadge setHidden:NO];
        self.unreadBadge.badgeText=[NSString stringWithFormat:@"%ld",_unreadCount];
    }else{
        [self.unreadBadge setHidden:YES];
    }
}

-(JSBadgeView*)unreadBadge{
    if(_unreadBadge==nil){
        _unreadBadge=[[JSBadgeView alloc] initWithParentView:_myImageView alignment:JSBadgeViewAlignmentTopRight];
    }
    return _unreadBadge;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

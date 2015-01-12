//
//  CDImageTwoLabelTableCell.m
//  AVOSChatDemo
//
//  Created by lzw on 14/11/11.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDImageTwoLabelTableCell.h"
#import "CDUtils.h"

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
        if (_unreadCount < 9) {
            _unreadLabel.font = [UIFont systemFontOfSize:13];
        }else if(_unreadCount > 9 && _unreadCount < 99){
            _unreadLabel.font = [UIFont systemFontOfSize:12];
        }else{
            _unreadLabel.font = [UIFont systemFontOfSize:10];
        }
        [_unreadLabel setHidden:NO];
        [self.contentView bringSubviewToFront:_unreadLabel];
        _unreadLabel.text = [NSString stringWithFormat:@"%d",_unreadCount];
    }else{
        [_unreadLabel setHidden:YES];
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

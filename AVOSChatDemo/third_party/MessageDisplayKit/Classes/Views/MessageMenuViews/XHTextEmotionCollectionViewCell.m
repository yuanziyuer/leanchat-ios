//
//  XHTextEmotionCollectionViewCell.m
//  LeanChat
//
//  Created by lzw on 14/11/25.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "XHTextEmotionCollectionViewCell.h"

@interface XHTextEmotionCollectionViewCell()

@property (nonatomic,weak) UILabel* label;

-(void)setup;

@end

@implementation XHTextEmotionCollectionViewCell

-(void)setTextEmotion:(XHTextEmotion *)textEmotion{
    _textEmotion=textEmotion;
    _label.text=textEmotion.emotion;
}

-(void)setup{
    if(!_label){
        UILabel* label=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, kXHTextEmotionLabelSize, kXHTextEmotionLabelSize)];
        label.font=[label.font fontWithSize:25];
        [self.contentView addSubview:label];
        _label=label;
    }
}

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if(self){
        [self setup];
    }
    return self;
}

-(void)awakeFromNib{
    [self setup];
}

-(void)dealloc{
    _textEmotion=nil;
}

@end

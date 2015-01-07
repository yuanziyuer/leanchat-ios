//
//  CDNetworkStateView.m
//  LeanChat
//
//  Created by lzw on 15/1/5.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import "CDSessionStateView.h"

@implementation CDSessionStateView

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:199 / 255.0 blue:199 / 255.0 alpha:1];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, (self.frame.size.height - 20) / 2, 20, 20)];
        imageView.image = [UIImage imageNamed:@"messageSendFail"];
        [self addSubview:imageView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(imageView.frame) + 5, 0, self.frame.size.width - (CGRectGetMaxX(imageView.frame) + 15), self.frame.size.height)];
        label.font = [UIFont systemFontOfSize:15.0];
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"会话断开，请检查网络";
        [self addSubview:label];
    }
    return self;
}

-(instancetype)initWithWidth:(CGFloat)width{
    return [self initWithFrame:CGRectMake(0, 0, width, kCDSessionStateViewHight)];
}

-(void)observeSessionUpdate{
    NSNotificationCenter* center=[NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(sessionUpdated) name:NOTIFICATION_SESSION_UPDATED object:nil];
    [self sessionUpdated];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)sessionUpdated
{
    CDSessionManager* man=[CDSessionManager sharedInstance];
    if([CDUtils connected]==NO || [[man getSession] isPaused]){
        if([_delegate respondsToSelector:@selector(onSessionBrokenWithStateView:)])
            [_delegate onSessionBrokenWithStateView:self];
    }else{
        if([_delegate respondsToSelector:@selector(onSessionFineWithStateView:)]){
            [_delegate onSessionFineWithStateView:self];
        }
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_SESSION_UPDATED object:nil];
}

@end

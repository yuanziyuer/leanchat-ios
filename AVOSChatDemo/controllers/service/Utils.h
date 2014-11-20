//
//  Utils.h
//  AVOSChatDemo
//
//  Created by lzw on 14-10-24.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CDBlock)();

@interface Utils : NSObject

+(void)alert:(NSString*)msg;
+(NSString*)md5OfString:(NSString*)s;
+(void)alertError:(NSError*)error;

+(UIActivityIndicatorView*)showIndicatorAtView:(UIView*)hookView;

+(void)showNetworkIndicator;
+(void)hideNetworkIndicator;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+(void)filterError:(NSError*)error callback:(CDBlock)callback;

+(NSMutableArray*)setToArray:(NSMutableSet*)set;

+(void)setCellMarginsZero:(UITableViewCell*)cell;
+(void)setTableViewMarginsZero:(UITableView*)view;

@end

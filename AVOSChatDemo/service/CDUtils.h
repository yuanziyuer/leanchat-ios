//
//  Utils.h
//  AVOSChatDemo
//
//  Created by lzw on 14-10-24.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

typedef void (^CDBlock)();

@interface CDUtils : NSObject

+(void)alert:(NSString*)msg;
+(NSString*)md5OfString:(NSString*)s;
+(void)alertError:(NSError*)error;

+(UIActivityIndicatorView*)showIndicatorAtView:(UIView*)hookView;

+(void)showNetworkIndicator;
+(void)hideNetworkIndicator;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+(void)filterError:(NSError*)error callback:(CDBlock)callback;
+(void)logError:(NSError*)error callback:(CDBlock)callbak;

+(void)hideNetworkIndicatorAndAlertError:(NSError*)error;

#pragma mark - collection utils
+(NSMutableArray*)setToArray:(NSMutableSet*)set;
+(NSArray*)reverseArray:(NSArray*)originArray;

#pragma mark - view utils
+(void)setCellMarginsZero:(UITableViewCell*)cell;
+(void)setTableViewMarginsZero:(UITableView*)view;
+(void)stopRefreshControl:(UIRefreshControl*)refreshControl;

#pragma mark - AVUtils

+(void)setPolicyOfAVQuery:(AVQuery*)query isNetwokOnly:(BOOL)onlyNetwork;

#pragma mark - async
+(void)runInGlobalQueue:(void (^)())queue;
+(void)runInMainQueue:(void (^)())queue;


@end

//
//  Utils.m
//  AVOSChatDemo
//
//  Created by lzw on 14-10-24.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "CDUtils.h"
#import "CDCommonDefine.h"
#import <CommonCrypto/CommonDigest.h>

@implementation CDUtils
+(void)alert:(NSString*)msg{
    UIAlertView *alertView=[[UIAlertView alloc]
                             initWithTitle:nil message:msg delegate:nil
                             cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}

+(void)alertError:(NSError*)error{
    [CDUtils alert:[error localizedDescription]];
}

+(NSString*)md5OfString:(NSString*)s{
    const char *ptr = [s UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+(UIActivityIndicatorView*)showIndicatorAtView:(UIView*)hookView{
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake(hookView.frame.size.width * 0.5, hookView.frame.size.height * 0.5-50);
    [hookView addSubview:indicator];
    [hookView bringSubviewToFront:indicator];
    indicator.hidden=NO;
    [indicator startAnimating];
    return indicator;
}

+(void)showNetworkIndicator{
    UIApplication* app=[UIApplication sharedApplication];
    app.networkActivityIndicatorVisible=YES;
}

+(void)hideNetworkIndicator{
    UIApplication* app=[UIApplication sharedApplication];
    app.networkActivityIndicatorVisible=NO;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(void)filterError:(NSError*)error callback:(CDBlock)callback{
    if(error){
        [CDUtils alertError:error];
    }else{
        callback();
    }
}

+(void)logError:(NSError*)error callback:(CDBlock)callback{
    if(error){
        NSLog(@"%@",[error localizedDescription]);
    }else{
        callback();
    }
}

+(NSMutableArray*)setToArray:(NSMutableSet*)set{
    return [[NSMutableArray alloc] initWithArray:[set allObjects]];
}

+(void)setCellMarginsZero:(UITableViewCell*)cell{
    if([cell respondsToSelector:@selector(layoutMargins)]){
        cell.layoutMargins=UIEdgeInsetsZero;
    }
}

+(void)setTableViewMarginsZero:(UITableView*)view{
    if(SYSTEM_VERSION<8){
        if ([view respondsToSelector:@selector(setSeparatorInset:)]) {
            [view setSeparatorInset:UIEdgeInsetsZero];
        }
    }else{
        if ([view respondsToSelector:@selector(layoutMargins)]) {
            view.layoutMargins = UIEdgeInsetsZero;
        }
    }
}

+(void)setPolicyOfAVQuery:(AVQuery*)query isNetwokOnly:(BOOL)onlyNetwork{
    [query setCachePolicy:onlyNetwork ? kAVCachePolicyNetworkOnly : kAVCachePolicyNetworkElseCache];
}

+(void)stopRefreshControl:(UIRefreshControl*)refreshControl{
    if(refreshControl!=nil && [[refreshControl class] isSubclassOfClass:[UIRefreshControl class]]){
        [refreshControl endRefreshing];
    }
}


@end

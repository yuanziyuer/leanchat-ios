//
//  CDAVUtils.h
//  LeanChat
//
//  Created by lzw on 15/3/9.
//  Copyright (c) 2015年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

@interface CDAVUtils : NSObject

+(void)setPolicyOfAVQuery:(AVQuery*)query isNetwokOnly:(BOOL)onlyNetwork;

@end

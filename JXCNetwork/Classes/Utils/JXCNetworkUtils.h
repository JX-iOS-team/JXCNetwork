//
//  JXCNetworkUtils.h
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXCBaseRequest.h"

@interface JXCNetworkUtils : NSObject

+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;

+ (void)addDoNotBackupAttribute:(NSString *)path;

+ (NSString *)md5StringFromString:(NSString *)string;

+ (NSString *)appVersionString;

+ (NSStringEncoding)stringEncodingWithRequest:(JXCBaseRequest *)request;

+ (BOOL)validateResumeData:(NSData *)data;


@end




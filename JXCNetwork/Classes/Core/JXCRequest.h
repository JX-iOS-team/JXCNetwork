//
//  JXCRequest.h
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import "JXCBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const YTKRequestCacheErrorDomain;

NS_ENUM(NSInteger) {
    YTKRequestCacheErrorExpired = -1,
    YTKRequestCacheErrorVersionMismatch = -2,
    YTKRequestCacheErrorSensitiveDataMismatch = -3,
    YTKRequestCacheErrorAppVersionMismatch = -4,
    YTKRequestCacheErrorInvalidCacheTime = -5,
    YTKRequestCacheErrorInvalidMetadata = -6,
    YTKRequestCacheErrorInvalidCacheData = -7,
    };
@interface JXCRequest : JXCBaseRequest


- (void)startWithoutCache;

@end

NS_ASSUME_NONNULL_END

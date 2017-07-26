//
//  JXCNetworkProxy.h
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "JXCBaseRequest.h"


NS_ASSUME_NONNULL_BEGIN


@class JXCBaseRequest;


@interface JXCNetworkProxy : NSObject


- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared agent.
+ (JXCNetworkProxy *)sharedProxy;

///  Add request to session and start it.
- (void)addRequest:(JXCBaseRequest *)request;

///  Cancel a request that was previously added.
- (void)cancelRequest:(JXCBaseRequest *)request;

///  Cancel all requests that were previously added.
- (void)cancelAllRequests;

///  Return the constructed URL of request.
///
///  @param request The request to parse. Should not be nil.
///
///  @return The result URL.
- (NSString *)buildRequestUrl:(JXCBaseRequest *)request;




@end

NS_ASSUME_NONNULL_END

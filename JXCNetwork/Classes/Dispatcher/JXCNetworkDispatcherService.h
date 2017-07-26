//
//  JXCNetworkDispatcherService.h
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JXCNetworkDispatcherServiceProtocol <NSObject>

@property (nonatomic, readonly) NSString *apiBaseUrl;

@property (nonatomic, readonly) NSString *apiVersion;

@optional

//为某些Service需要拼凑额外字段到URL处
- (NSDictionary *)extraParmas;

//为某些Service需要拼凑额外的HTTPToken，如accessToken signature
- (NSDictionary *)extraHttpHeadParmasWithParmas:(NSDictionary *)parmas;


@end

@interface JXCNetworkDispatcherService : NSObject

@property (nonatomic, strong, readonly) NSString *publicKey;
@property (nonatomic, strong, readonly) NSString *privateKey;
@property (nonatomic, strong, readonly) NSString *apiBaseUrl;
@property (nonatomic, strong, readonly) NSString *apiVersion;

@property (nonatomic, weak, readonly) id<JXCNetworkDispatcherServiceProtocol> child;


@end

NS_ASSUME_NONNULL_END

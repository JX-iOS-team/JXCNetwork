//
//  JXCNetworkDispatcherManager.h
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXCNetworkDispatcherService.h"


@protocol JXCNetworkDispatcherManagerDelegate <NSObject>

/*
 * key为service的Identifier
 * value为service的Class的字符串
 */
- (NSDictionary<NSString *,NSString *> *)servicesKindsOfServiceManager;

@end


@interface JXCNetworkDispatcherManager : NSObject


@property (nonatomic, weak) id<JXCNetworkDispatcherManagerDelegate> managerDelegate;

+ (instancetype)sharedInstance;
- (JXCNetworkDispatcherService<JXCNetworkDispatcherServiceDelegate> *)serviceWithIdentifier:(NSString *)identifier;


@end

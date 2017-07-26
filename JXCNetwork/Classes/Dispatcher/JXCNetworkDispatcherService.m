//
//  JXCNetworkDispatcherService.m
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import "JXCNetworkDispatcherService.h"

@interface JXCNetworkDispatcherService()

@property (nonatomic, weak, readwrite) id<JXCNetworkDispatcherServiceProtocol> child;

@end
@implementation JXCNetworkDispatcherService


- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([self conformsToProtocol:@protocol(JXCNetworkDispatcherServiceProtocol)]) {
            self.child = (id<JXCNetworkDispatcherServiceProtocol>)self;
        }
    }
    return self;
}


@end

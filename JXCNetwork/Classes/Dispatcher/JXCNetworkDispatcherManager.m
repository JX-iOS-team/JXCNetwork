//
//  JXCNetworkDispatcherManager.m
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import "JXCNetworkDispatcherManager.h"



@interface JXCNetworkDispatcherManager ()

@property (nonatomic, strong) NSMutableDictionary *serviceList;

@end

@implementation JXCNetworkDispatcherManager


#pragma mark - getters and setters
- (NSMutableDictionary *)serviceList
{
    if (_serviceList == nil) {
        _serviceList = [[NSMutableDictionary alloc] init];
    }
    return _serviceList;
}

#pragma mark - life cycle
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static JXCNetworkDispatcherManager *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[JXCNetworkDispatcherManager alloc] init];
    });
    return sharedInstance;
}


#pragma mark - public methods
- (JXCNetworkDispatcherService<JXCNetworkDispatcherServiceDelegate> *)serviceWithIdentifier:(NSString *)identifier{
    NSAssert(self.managerDelegate, @"必须提供managerDelegate绑定并实现servicesKindsOfServiceManager方法，否则无法正常使用Service模块");
    
    if (self.serviceList[identifier] == nil) {
        self.serviceList[identifier] = [self newServiceWithIdentifier:identifier];
    }
    return self.serviceList[identifier];
}

#pragma mark - private methods

- (JXCNetworkDispatcherService<JXCNetworkDispatcherServiceDelegate> *)newServiceWithIdentifier:(NSString *)identifier
{
    NSAssert([self.managerDelegate respondsToSelector:@selector(servicesKindsOfServiceManager)], @"请实现 JXCNetworkDispatcherManagerDelegate 的 servicesKindsOfServiceManager 方法");
    
    if ([[self.managerDelegate servicesKindsOfServiceManager]valueForKey:identifier]) {
        NSString *classStr = [[self.managerDelegate servicesKindsOfServiceManager]valueForKey:identifier];
        id service = [[NSClassFromString(classStr) alloc]init];
        NSAssert(service, [NSString stringWithFormat:@"无法创建 service，请检查 servicesKindsOfServiceManager 提供的数据是否正确"],service);
        NSAssert([service conformsToProtocol:@protocol(JXCNetworkDispatcherServiceDelegate)], @"你提供的 Service 没有遵循 JXCNetworkDispatcherServiceDelegate");
        return service;
    }else {
        NSAssert(NO, @" servicesKindsOfServiceManager 中无法找不到相匹配 identifier ");
    }
    
    return nil;
}




@end

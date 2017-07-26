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
- (JXCNetworkDispatcherService<JXCNetworkDispatcherServiceProtocol> *)serviceWithIdentifier:(NSString *)identifier{
    NSAssert(self.dataSource, @"必须提供dataSource绑定并实现servicesKindsOfServiceManager方法，否则无法正常使用Service模块");
    
    if (self.serviceList[identifier] == nil) {
        self.serviceList[identifier] = [self newServiceWithIdentifier:identifier];
    }
    return self.serviceList[identifier];
}

#pragma mark - private methods

- (JXCNetworkDispatcherService<JXCNetworkDispatcherServiceProtocol> *)newServiceWithIdentifier:(NSString *)identifier
{
    NSAssert([self.dataSource respondsToSelector:@selector(servicesKindsOfServiceManager)], @"请实现JXCNetworkDispatcherManagerDataSource的servicesKindsOfServiceManager方法");
    
    if ([[self.dataSource servicesKindsOfServiceManager]valueForKey:identifier]) {
        NSString *classStr = [[self.dataSource servicesKindsOfServiceManager]valueForKey:identifier];
        id service = [[NSClassFromString(classStr) alloc]init];
        NSAssert(service, [NSString stringWithFormat:@"无法创建service，请检查servicesKindsOfServiceManager提供的数据是否正确"],service);
        NSAssert([service conformsToProtocol:@protocol(JXCNetworkDispatcherServiceProtocol)], @"你提供的Service没有遵循JXCNetworkDispatcherServiceProtocol");
        return service;
    }else {
        NSAssert(NO, @"servicesKindsOfServiceManager中无法找不到相匹配identifier");
    }
    
    return nil;
}




@end

//
//  JXCRequest.m
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import "JXCRequest.h"

@implementation JXCRequest

- (void)start {
    [self startWithoutCache];
    return;
}

- (void)startWithoutCache {
    [super start];
}

@end

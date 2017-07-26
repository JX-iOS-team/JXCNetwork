//
//  JXCNetwork.h
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/24.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifndef _JXCNETWORK_
    #define _JXCNETWORK_

#if __has_include(<JXCNetwork/JXCNetwork.h>)

    //! Project version number for JXCNetwork.
    FOUNDATION_EXPORT double JXCNetworkVersionNumber;

    //! Project version string for JXCNetwork.
    FOUNDATION_EXPORT const unsigned char JXCNetworkVersionString[];

    #import <JXCNetwork/JXCRequest.h>
    #import <JXCNetwork/JXCBaseRequest.h>
    #import <JXCNetwork/JXCNetworkProxy.h>
    #import <JXCNetwork/JXCNetworkDispatcherManager.h>

#else

    #import "JXCRequest.h"
    #import "JXCBaseRequest.h"
    #import "JXCNetworkProxy.h"
    #import "JXCNetworkDispatcherManager.h"


#endif /* __has_include */

#endif /* _JXCNETWORK_ */





//
//  JXCBaseRequest.m
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import "JXCBaseRequest.h"
#import "JXCNetworkProxy.h"



NSString *const JXCRequestValidationErrorDomain = @"com.jxssy.network.framework.request.validation";

@interface JXCBaseRequest ()

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) id responseJSONObject;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) NSError *error;

@end


@implementation JXCBaseRequest

#pragma mark - Request and Response Information

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (NSDictionary *)responseHeaders {
    return self.response.allHeaderFields;
}

- (NSURLRequest *)currentRequest {
    return self.requestTask.currentRequest;
}

- (NSURLRequest *)originalRequest {
    return self.requestTask.originalRequest;
}

- (BOOL)isCancelled {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

#pragma mark - Request Configuration

- (void)setCompletionBlockWithSuccess:(JXCRequestCompletionBlock)success
                              failure:(JXCRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}


#pragma mark - Request Action

- (void)start {
    [[JXCNetworkProxy sharedProxy] addRequest:self];
}

- (void)stop {
    self.delegate = nil;
    [[JXCNetworkProxy sharedProxy] cancelRequest:self];
}

- (void)startWithCompletionBlockWithSuccess:(JXCRequestCompletionBlock)success
                                    failure:(JXCRequestCompletionBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

#pragma mark - Subclass Override

- (void)requestCompletePreprocessor {
}

- (void)requestCompleteFilter {
}

- (void)requestFailedPreprocessor {
}

- (void)requestFailedFilter {
}

- (NSString *)requestUrl {
    return @"";
}
/// dispatcher name
- (NSString *)serviceName{
    return @"";
}
- (NSString *)baseUrl {
    return @"";
}

- (NSTimeInterval)requestTimeoutInterval {
    return 60;
}

- (id)requestArgument {
    return nil;
}

- (id)cacheFileNameFilterForRequestArgument:(id)argument {
    return argument;
}

- (JXCRequestMethod)requestMethod {
    return JXCRequestMethodGET;
}

- (JXCRequestSerializerType)requestSerializerType {
    return JXCRequestSerializerTypeHTTP;
}

- (JXCResponseSerializerType)responseSerializerType {
    return JXCResponseSerializerTypeJSON;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return nil;
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    return nil;
}

- (NSURLRequest *)buildCustomUrlRequest {
    return nil;
}


- (BOOL)allowsCellularAccess {
    return YES;
}

- (id)jsonValidator {
    return nil;
}

- (BOOL)statusCodeValidator {
    NSInteger statusCode = [self responseStatusCode];
    return (statusCode >= 200 && statusCode <= 299);
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod, self.requestArgument];
}

@end

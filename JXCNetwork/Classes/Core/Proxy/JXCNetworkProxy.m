//
//  JXCNetworkProxy.m
//  JXCNetwork
//
//  Created by 任我行 on 2017/7/25.
//  Copyright © 2017年 Redata Team @ JX Cloud. All rights reserved.
//

#import "JXCNetworkProxy.h"
#import <pthread/pthread.h>
#import "JXCNetworkPrivate.h"
#import "JXCNetworkUtils.h"
#import "JXCNetworkDispatcherManager.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)



@implementation JXCNetworkProxy{
    
    AFHTTPSessionManager *_sessionManager;
    //JXCNetworkConfig *_config;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlParserResponseSerialzier;
    NSMutableDictionary<NSNumber *, JXCBaseRequest *> *_requestsRecord;
    
    dispatch_queue_t _processingQueue;
    pthread_mutex_t _lock;
    NSIndexSet *_allStatusCodes;

}


+ (JXCNetworkProxy *)sharedProxy {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //_config = [JXCNetworkConfig sharedConfig];
        //_manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
        _requestsRecord = [NSMutableDictionary dictionary];
        _processingQueue = dispatch_queue_create("com.jxssy.networkproxy.processing", DISPATCH_QUEUE_CONCURRENT);
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        pthread_mutex_init(&_lock, NULL);
        
        if (_sessionManager == nil) {
            _sessionManager = [AFHTTPSessionManager manager];
            _sessionManager.securityPolicy = [AFSecurityPolicy defaultPolicy];
            _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            // Take over the status code validation
            _sessionManager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
            _sessionManager.completionQueue = _processingQueue;
        }
    }
    return self;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
        
    }
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    if (!_xmlParserResponseSerialzier) {
        _xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
        _xmlParserResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
    }
    return _xmlParserResponseSerialzier;
}

#pragma mark -

- (NSString *)buildRequestUrl:(JXCBaseRequest *)request {
    NSParameterAssert(request != nil);
    
    NSString *detailUrl = [request requestUrl];
    NSURL *temp = [NSURL URLWithString:detailUrl];
    // If detailUrl is valid URL
    if (temp && temp.host && temp.scheme) {
        return detailUrl;
    }

    
    NSString *baseUrl;
    if ([request baseUrl].length > 0) {
        baseUrl = [request baseUrl];
    } else {
        JXCNetworkDispatcherService *service = [[JXCNetworkDispatcherManager sharedInstance] serviceWithIdentifier:request.serviceName];
        baseUrl = service.apiBaseUrl;
    }
    
    // URL slash compability
    NSURL *url = [NSURL URLWithString:baseUrl];
    
    if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    return [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString;
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(JXCBaseRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == JXCRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == JXCRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    requestSerializer.timeoutInterval = [request requestTimeoutInterval];
    requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
    
    // If api needs server username and password
    NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
                                                          password:authorizationHeaderFieldArray.lastObject];
    }
    
    // If api needs to add custom value to HTTPHeaderField
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    
    
    // dispatcher header value to HTTPHeaderField
    id requestParams = request.requestArgument;
    JXCNetworkDispatcherService *service = [[JXCNetworkDispatcherManager sharedInstance] serviceWithIdentifier:request.serviceName];
    
    if ([service.child respondsToSelector:@selector(extraHttpHeadParmasWithParmas:)]) {
        NSDictionary *dict = [service.child extraHttpHeadParmasWithParmas:requestParams];
        if (dict) {
            [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [requestSerializer setValue:obj forHTTPHeaderField:key];
            }];
        }
    }
    
    return requestSerializer;
}

- (NSURLSessionTask *)sessionTaskForRequest:(JXCBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    JXCRequestMethod method = [request requestMethod];
    NSString *url = [self buildRequestUrl:request];
    id param = request.requestArgument;
    AFConstructingBlock constructingBlock = [request constructingBodyBlock];
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    
    switch (method) {
        case JXCRequestMethodGET:
            if (request.resumableDownloadPath) {
                return [self downloadTaskWithDownloadPath:request.resumableDownloadPath requestSerializer:requestSerializer URLString:url parameters:param progress:request.resumableDownloadProgressBlock error:error];
            } else {
                return [self dataTaskWithHTTPMethod:@"GET" requestSerializer:requestSerializer URLString:url parameters:param error:error];
            }
        case JXCRequestMethodPOST:
            return [self dataTaskWithHTTPMethod:@"POST" requestSerializer:requestSerializer URLString:url parameters:param constructingBodyWithBlock:constructingBlock error:error];
        case JXCRequestMethodHEAD:
            return [self dataTaskWithHTTPMethod:@"HEAD" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case JXCRequestMethodPUT:
            return [self dataTaskWithHTTPMethod:@"PUT" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case JXCRequestMethodDELETE:
            return [self dataTaskWithHTTPMethod:@"DELETE" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case JXCRequestMethodPATCH:
            return [self dataTaskWithHTTPMethod:@"PATCH" requestSerializer:requestSerializer URLString:url parameters:param error:error];
    }
}

- (void)addRequest:(JXCBaseRequest *)request {
    NSParameterAssert(request != nil);
    
    NSError * __autoreleasing requestSerializationError = nil;
    
    NSURLRequest *customUrlRequest= [request buildCustomUrlRequest];
    if (customUrlRequest) {
        __block NSURLSessionDataTask *dataTask = nil;
        dataTask = [_sessionManager dataTaskWithRequest:customUrlRequest completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [self handleRequestResult:dataTask responseObject:responseObject error:error];
        }];
        request.requestTask = dataTask;
    } else {
        request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    }
    
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }
    
    NSAssert(request.requestTask != nil, @"requestTask should not be nil");
    
    // Set request task priority
    // !!Available on iOS 8 +
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case JXCRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case JXCRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case JXCRequestPriorityDefault:
                /*!!fall through*/
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }
    
    // Retain request
    //JXCLog(@"Add request: %@", NSStringFromClass([request class]));
    [self addRequestToRecord:request];
    [request.requestTask resume];
}

- (void)cancelRequest:(JXCBaseRequest *)request {
    NSParameterAssert(request != nil);
    
    [request.requestTask cancel];
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            JXCBaseRequest *request = _requestsRecord[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [request stop];
        }
    }
}

- (BOOL)validateResult:(JXCBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:JXCRequestValidationErrorDomain code:JXCRequestValidationErrorInvalidStatusCode userInfo:@{NSLocalizedDescriptionKey:@"Invalid status code"}];
        }
        return result;
    }
    id json = [request responseJSONObject];
    id validator = [request jsonValidator];
    if (json && validator) {
        result = [JXCNetworkUtils validateJSON:json withValidator:validator];
        if (!result) {
            if (error) {
                *error = [NSError errorWithDomain:JXCRequestValidationErrorDomain code:JXCRequestValidationErrorInvalidJSONFormat userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
            }
            return result;
        }
    }
    return YES;
}

- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    JXCBaseRequest *request = _requestsRecord[@(task.taskIdentifier)];
    Unlock();
    
    // When the request is cancelled and removed from records, the underlying
    // AFNetworking failure callback will still kicks in, resulting in a nil `request`.
    //
    // Here we choose to completely ignore cancelled tasks. Neither success or failure
    // callback will be called.
    if (!request) {
        return;
    }
    
    //JXCLog(@"Finished Request: %@", NSStringFromClass([request class]));
    
    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;
    
    NSError *requestError = nil;
    BOOL succeed = NO;
    
    request.responseObject = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[JXCNetworkUtils stringEncodingWithRequest:request]];
        
        switch (request.responseSerializerType) {
            case JXCResponseSerializerTypeHTTP:
                // Default serializer. Do nothing.
                break;
            case JXCResponseSerializerTypeJSON:
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                request.responseJSONObject = request.responseObject;
                break;
            case JXCResponseSerializerTypeXMLParser:
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                break;
        }
    }
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    
    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

- (void)requestDidSucceedWithRequest:(JXCBaseRequest *)request {
    @autoreleasepool {
        [request requestCompletePreprocessor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        //[request toggleAccessoriesWillStopCallBack];
        [request requestCompleteFilter];
        
        if (request.delegate != nil) {
            [request.delegate requestFinished:request];
        }
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
        //[request toggleAccessoriesDidStopCallBack];
    });
}

- (void)requestDidFailWithRequest:(JXCBaseRequest *)request error:(NSError *)error {
    request.error = error;
//    JXCLog(@"Request %@ failed, status code = %ld, error = %@",
//           NSStringFromClass([request class]), (long)request.responseStatusCode, error.localizedDescription);
//    
    // Save incomplete download data.
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    if (incompleteDownloadData) {
//        [incompleteDownloadData writeToURL:[self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] atomically:YES];
    }
    
    // Load response from file and clean up if download task failed.
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[JXCNetworkUtils stringEncodingWithRequest:request]];
            
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    
    @autoreleasepool {
        [request requestFailedPreprocessor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        //[request toggleAccessoriesWillStopCallBack];
        [request requestFailedFilter];
        
        if (request.delegate != nil) {
            [request.delegate requestFailed:request];
        }
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
        //[request toggleAccessoriesDidStopCallBack];
    });
}

- (void)addRequestToRecord:(JXCBaseRequest *)request {
    Lock();
    _requestsRecord[@(request.requestTask.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(JXCBaseRequest *)request {
    Lock();
    [_requestsRecord removeObjectForKey:@(request.requestTask.taskIdentifier)];
    //JXCLog(@"Request queue size = %zd", [_requestsRecord count]);
    Unlock();
}

#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method requestSerializer:requestSerializer URLString:URLString parameters:parameters constructingBodyWithBlock:nil error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;
    
    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_sessionManager dataTaskWithRequest:request
                           completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error) {
                               [self handleRequestResult:dataTask responseObject:responseObject error:_error];
                           }];
    
    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error {
    // add parameters to URL;
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];
    
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    // If targetPath is a directory, use the file name we got from the urlRequest.
    // Make sure downloadTargetPath is always a file, not directory.
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }
    
    // AFN use `moveItemAtURL` to move downloaded file to target path,
    // this method aborts the move attempt if a file already exist at the path.
    // So we remove the exist file before we start the download task.
    // https://github.com/AFNetworking/AFNetworking/issues/3775
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
//    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self incompleteDownloadTempPathForDownloadPath:downloadPath].path];
//    NSData *data = [NSData dataWithContentsOfURL:[self incompleteDownloadTempPathForDownloadPath:downloadPath]];
//    BOOL resumeDataIsValid = [JXCNetworkUtils validateResumeData:data];
//    
//    BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
//    BOOL resumeSucceeded = NO;
//    __block NSURLSessionDownloadTask *downloadTask = nil;
//    // Try to resume with resumeData.
//    // Even though we try to validate the resumeData, this may still fail and raise excecption.
//    if (canBeResumed) {
//        @try {
//            downloadTask = [_manager downloadTaskWithResumeData:data progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//                return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
//            } completionHandler:
//                            ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//                                [self handleRequestResult:downloadTask responseObject:filePath error:error];
//                            }];
//            resumeSucceeded = YES;
//        } @catch (NSException *exception) {
//            JXCLog(@"Resume download failed, reason = %@", exception.reason);
//            resumeSucceeded = NO;
//        }
//    }
//    if (!resumeSucceeded) {
//        downloadTask = [_manager downloadTaskWithRequest:urlRequest progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
//        } completionHandler:
//                        ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//                            [self handleRequestResult:downloadTask responseObject:filePath error:error];
//                        }];
//    }
//    return downloadTask;
    return nil;
}

#pragma mark - Resumable Download

//- (NSString *)incompleteDownloadTempCacheFolder {
//    NSFileManager *fileManager = [NSFileManager new];
//    static NSString *cacheFolder;
//    
//    if (!cacheFolder) {
//        NSString *cacheDir = NSTemporaryDirectory();
//        cacheFolder = [cacheDir stringByAppendingPathComponent:kJXCNetworkIncompleteDownloadFolderName];
//    }
//    
//    NSError *error = nil;
//    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
//        JXCLog(@"Failed to create cache directory at %@", cacheFolder);
//        cacheFolder = nil;
//    }
//    return cacheFolder;
//}
//
//- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
//    NSString *tempPath = nil;
//    NSString *md5URLString = [JXCNetworkUtils md5StringFromString:downloadPath];
//    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
//    return [NSURL fileURLWithPath:tempPath];
//}



//- (NSURLRequest *)generateRequestWithServiceIdentifier:(NSString *)serviceIdentifier
//                                         requestParams:(NSDictionary *)requestParams
//                                            methodName:(NSString *)methodName
//                                     requestWithMethod:(NSString *)method {
//    JXCNetworkDispatcherService *service = [[JXCNetworkDispatcherManager sharedInstance] serviceWithIdentifier:serviceIdentifier];
//
//    NSDictionary *totalRequestParams = [self totalRequestParamsByService:service requestParams:requestParams];
//    
//    NSMutableURLRequest *request = [self.httpRequestSerializer requestWithMethod:method URLString:urlString parameters:totalRequestParams error:NULL];
//    
//    if (![method isEqualToString:@"GET"] && [CTNetworkingConfigurationManager sharedInstance].shouldSetParamsInHTTPBodyButGET) {
//        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:requestParams options:0 error:NULL];
//    }
//    
//    if ([service.child respondsToSelector:@selector(extraHttpHeadParmasWithParmas:)]) {
//        NSDictionary *dict = [service.child extraHttpHeadParmasWithParmas:requestParams];
//        if (dict) {
//            [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//                [request setValue:obj forHTTPHeaderField:key];
//            }];
//        }
//    }
//    
//    request.requestParams = totalRequestParams;
//    return request;
//}


#pragma mark - private method
//根据Service拼接额外参数
- (NSDictionary *)totalRequestParamsByService:(JXCNetworkDispatcherService *)service requestParams:(NSDictionary *)requestParams {
    NSMutableDictionary *totalRequestParams = [NSMutableDictionary dictionaryWithDictionary:requestParams];
    
    if ([service.child respondsToSelector:@selector(extraParmas)]) {
        if ([service.child extraParmas]) {
            [[service.child extraParmas] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [totalRequestParams setObject:obj forKey:key];
            }];
        }
    }
    return [totalRequestParams copy];
}




#pragma mark - ext get and set

- (AFHTTPSessionManager *)sessionManager {
    return _sessionManager;
}

- (void)resetURLSessionManager {
    _sessionManager = [AFHTTPSessionManager manager];
}

- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration {
    _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
}



@end

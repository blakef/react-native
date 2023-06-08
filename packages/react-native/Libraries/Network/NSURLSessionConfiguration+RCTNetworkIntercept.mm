/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <objc/message.h>
#import <objc/runtime.h>
#import <React/RCTUtils.h>
#import "NSURLSessionConfiguration+RCTNetworkIntercept.h"

static NSNumber *const RCTNetworkMaxBody = @1048576;
static NSString *const REQUEST_ID = @"RCTNetworkObserverProtocol.requestId";

@implementation RCTNetworkObserverProtocol

#pragma mark NSURLProtocol implementations

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task
{
  if (!task.currentRequest.URL) {
    return NO;
  }

  NSString *scheme = task.currentRequest.URL.scheme;
  if (!([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
    return NO;
  }

  BOOL isNewRequest = [self propertyForKey:REQUEST_ID inRequest:task.currentRequest] == nil;
  return isNewRequest;
}

- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    
    NSLog(@"Initialised a willSendRequest: %@", request);
    
    return self;
}

- (id)initWithTask:(NSURLSessionTask *)task
    cachedResponse:(NSCachedURLResponse *)cachedResponse
            client:(id<NSURLProtocolClient>)client
{
  self = [super init];

  NSLog(@"Initialised a task: %@", task);
    
  return self;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
  return request;
}

- (void)startLoading
{
  // TODO
}

- (void)stopLoading
{
  // TODO
}

#pragma mark NSURLSessionDataDelegate implementations

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    id key = [NSURLProtocol propertyForKey:REQUEST_ID inRequest:request];
    if (key) {
        NSLog(@"Existing URLSession(%@)", key);
    } else {
        NSLog(@"New URLSession(%@)", request.URL);
    }
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSLog(@"is NSHTTPURLResponse");
        NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
        NSString *contentType = [resp valueForHTTPHeaderField:@"Content-Type"];
        BOOL isText = [contentType hasPrefix:@"text/"] || [contentType isEqualToString:@"application/json"];
        NSLog(@"NSHTTPURLResponse(content-type%@, isText:%@, length:%lld", contentType, isText ? @"text" : @"other", [resp expectedContentLength]);
        
    } else {
        NSLog(@"is NOT NSHTTPURLResponse");
    }
}

@end

@implementation NSURLSessionConfiguration (RCTNetworkIntercept)

+ (void)load
{
#if DEBUG
  NSLog(@"RCTNetworkObserver IS logging network activity to CDP");

  static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"XXX: Swizzling");
        
        //
        // Method 1: explicityly swap class method implementations
        //
        Class cls = [NSURLSessionConfiguration class];
        
        /*
        SEL original = @selector(defaultSessionConfiguration);
        Method originalMethod = class_getClassMethod(cls, original);
        IMP originalImpl = class_getMethodImplementation(cls, original);
        
        const char *originalArgTypes = method_getTypeEncoding(originalMethod);
        
        SEL replacement = @selector(RCTNetworkIntercept_NSURLSessionConfiguration);
        Method replacementMethod = class_getClassMethod(cls, replacement);
        IMP replacementImpl = class_getMethodImplementation(cls, replacement);
        
        if (class_addMethod(cls, original, replacementImpl, method_getTypeEncoding(replacementMethod))) {
            class_replaceMethod(cls, replacement, originalImpl, method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, replacementMethod);
        }
         */
        
        //
        // Method 2: Use our util class to swap.
        //
        SEL original = @selector(defaultSessionConfiguration);
        SEL replacement = @selector(RCTNetworkIntercept_NSURLSessionConfiguration);
        RCTSwapClassMethods(cls, original, replacement);
        
        // Validation, I'd expect to see the RCTNetworkObserverProtocol class in this list at index 0.
        NSLog(@"Does RCTNetworkObserverProtocol exist -> %@", [NSURLSessionConfiguration defaultSessionConfiguration].protocolClasses);
    });
  ;
#else
  NSLog(@"RCTNetworkObserver NOT logging network activity to CDP");
#endif
    
NSLog(@"defaultSessionConfiguration? %@", [NSURLSessionConfiguration defaultSessionConfiguration].protocolClasses);
}

// We swizzle this into NSURLSessionConfig.defaultSessionConfiguration
+ (NSURLSessionConfiguration *)RCTNetworkIntercept_NSURLSessionConfiguration
{
  NSURLSessionConfiguration *config = [self defaultSessionConfiguration];

  NSLog(@"[Swizzled urlSessionConfiguration] Adding proxy + using old config: %@", config);
  
  NSArray *existing = config.protocolClasses == nil ? config.protocolClasses : @[];
  NSMutableArray *proto = [[NSMutableArray alloc] init];

  [proto addObject:[RCTNetworkObserverProtocol class]];
  if (config.protocolClasses) {
    [proto addObjectsFromArray:config.protocolClasses];
  }
  config.protocolClasses = proto;

  return config;
}

@end


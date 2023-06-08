/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTUtils.h>

@interface RCTNetworkObserverProtocol : NSURLProtocol <NSURLSessionDataDelegate>

@end

/*
 * NSURLSessionConfiguration extension that intercepts network requests to include in Chrome DevTools Protocols
 * (CDP) output in debug builds only.
 */
@interface NSURLSessionConfiguration (RCTNetworkIntercept)

+ (NSURLSessionConfiguration *)RCTNetworkIntercept_NSURLSessionConfiguration;

@end


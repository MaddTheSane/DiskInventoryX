//
//  NTProxy.h
//  CocoatechCore
//
//  Created by Steve Gehrman on 7/30/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTProxy : NSObject 
{
	id __unsafe_unretained object;
}

@property (unsafe_unretained) id object;  // not retained, atomic on purpose

+ (NTProxy*)proxyWithObject:(id)theObject;
@end

@interface NSArray (NTProxy)
- (NSUInteger)indexOfProxyObjectIdenticalTo:(id)theObject;
@end

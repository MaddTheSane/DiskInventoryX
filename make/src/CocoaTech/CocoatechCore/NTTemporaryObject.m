//
//  NTTemporaryObject.m
//  CocoatechCore
//
//  Created by Steve Gehrman on 1/4/10.
//  Copyright 2010 Cocoatech. All rights reserved.
//

#import "NTTemporaryObject.h"
#import "NSThread-NTExtensions.h"

@interface NTTemporaryObject ()
@property (strong) id contents;  // thread safe
@end

@implementation NTTemporaryObject

@synthesize contents;

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 

+ (NTTemporaryObject*)tempObject:(id)theContents timeToLive:(NSTimeInterval)timeToLive;
{
	NTTemporaryObject* result = [[NTTemporaryObject alloc] init];
	
	result.contents = theContents;
	
	[result performDelayedSelector:@selector(releaseContentsAfterDelay) withObject:nil delay:timeToLive];
	
	return result;
}

- (void)releaseContentsAfterDelay;
{
	self.contents = nil;
}

@end

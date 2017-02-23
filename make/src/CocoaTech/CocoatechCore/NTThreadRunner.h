//
//  NTThreadRunner.h
//  CocoatechCore
//
//  Created by Steve Gehrman on 8/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTThreadRunner, NTThreadRunnerParam, NTThreadHelper;

@protocol NTThreadRunnerDelegateProtocol <NSObject>
// called on main thread
- (void)threadRunner_complete:(NTThreadRunner*)threadRunner;
@end

@interface NTThreadRunner : NSObject
{
	__unsafe_unretained id<NTThreadRunnerDelegateProtocol> mv_delegate;
	
	CGFloat mv_priority;
	
	NTThreadRunnerParam* mv_param;
	NTThreadHelper* mv_threadHelper;
}

+ (NTThreadRunner*)thread:(NTThreadRunnerParam*)param
				 priority:(CGFloat)priority
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;  // state is kNormalThreadState

- (void)clearDelegate; // also kills the thread if still running

- (NTThreadRunnerParam *)param;
@property (readonly, strong) NTThreadHelper *threadHelper;

@end

// -------------------------------------------------------------------------

@interface NTThreadRunnerParam : NSObject
{
	__unsafe_unretained NTThreadRunner* mv_runner;
}

// must subclass to do work
- (BOOL)doThreadProc;

@property (assign, readonly) NTThreadRunner *runner;
- (NTThreadHelper *)helper;

- (id<NTThreadRunnerDelegateProtocol>)delegate;

@end

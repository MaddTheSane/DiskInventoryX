//
//  NTThreadRunner.m
//  CocoatechCore
//
//  Created by Steve Gehrman on 8/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "NTThreadRunner.h"
#import "NTThreadHelper.h"
#import "NSThread-NTExtensions.h"


@interface NTThreadRunner (Thread)
- (void)threadProc:(NTThreadRunnerParam*)param;
@end


@interface NTThreadRunnerParam ()
@property (assign, readwrite) NTThreadRunner *runner;
@end

@interface NTThreadRunner ()
@property (assign) id<NTThreadRunnerDelegateProtocol> delegate;

@property (readwrite, strong) NTThreadHelper *threadHelper;

@property CGFloat priority;

- (void)setParam:(NTThreadRunnerParam *)theParam;

@end

@implementation NTThreadRunner
@synthesize priority = mv_priority;
@synthesize delegate = mv_delegate;
@synthesize threadHelper = mv_threadHelper;

- (void)dealloc;
{
	if ([self delegate])
		[NSException raise:@"must call clearDelegate" format:@"%@", NSStringFromClass([self class])];
	
	[self setThreadHelper:nil];
	[self setParam:nil];

}

- (void)clearDelegate; // also kills the thread
{
	if (![[self threadHelper] complete])
		[mv_threadHelper setKilled:YES];
	
	[self setDelegate:nil];
	
	// resume incase the thread is paused
	[[self threadHelper] resume];
}

+ (NTThreadRunner*)thread:(NTThreadRunnerParam*)param
				 priority:(CGFloat)priority
				 delegate:(id<NTThreadRunnerDelegateProtocol>)delegate;
{
	NTThreadRunner* result = [[NTThreadRunner alloc] init];
	
	[result setDelegate:delegate];
	[result setPriority:priority];
	[result setThreadHelper:[NTThreadHelper threadHelper]];
	[result setParam:param];
		
	[NSThread detachNewThreadSelector:@selector(threadProc:) toTarget:result withObject:param];
	
	return result;
}

//---------------------------------------------------------- 
//  param 
//---------------------------------------------------------- 
- (NTThreadRunnerParam *)param
{
    return mv_param; 
}

- (void)setParam:(NTThreadRunnerParam *)theParam
{
    if (mv_param != theParam) {
		[mv_param setRunner:nil];
		
        mv_param = theParam;
		
		[mv_param setRunner:self];
    }
}

@end

// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

@implementation NTThreadRunnerParam
@synthesize runner = mv_runner;


//---------------------------------------------------------- 
//  threadRunner 
//---------------------------------------------------------- 
- (NTThreadHelper *)helper
{
    return [[self runner] threadHelper]; 
}

- (id<NTThreadRunnerDelegateProtocol>)delegate;
{
	return [[self runner] delegate];
}

// must subclass to do work
- (BOOL)doThreadProc;
{
	return NO;
}

@end

@implementation NTThreadRunner (Thread)

- (void)threadProc:(NTThreadRunnerParam*)param;
{
	@autoreleasepool {
		
		[NSThread setThreadPriority:[self priority]];
		
		if ([param doThreadProc])
			[self performSelectorOnMainThread:@selector(mainThreadCallback) withObject:nil];
		
		[[self threadHelper] setComplete:YES];
		
	}
}

- (void)mainThreadCallback;
{
	[[self delegate] threadRunner_complete:self];
}

@end

//
//  NTDoubleClickHandler.m
//  CocoatechCore
//
//  Created by Steve Gehrman on Fri Mar 07 2003.
//  Copyright (c) 2003 CocoaTech. All rights reserved.
//

#import "NTDoubleClickHandler.h"
#import "NTRevealParameters.h"

@implementation NTDoubleClickHandler

+ (NTDoubleClickHandler*)sharedInstance;
{
    static id shared=nil;

    if (!shared)
        shared = [[NTDoubleClickHandler alloc] init];

    return shared;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setDelegate:nil];
}

//---------------------------------------------------------- 
//  delegate 
//---------------------------------------------------------- 
- (id <NTDoubleClickDelegateProtocol>)delegate
{
    return mDelegate; 
}

- (void)setDelegate:(id <NTDoubleClickDelegateProtocol>)theDelegate
{
    if (mDelegate != theDelegate)
    {
        mDelegate = theDelegate;
    }
}

- (void)handleDoubleClick:(id)object startRect:(NSRect)startRect window:(NSWindow*)window params:(NTRevealParameters*)params;
{
    if ([self delegate])
        [[self delegate] handleDoubleClick:object startRect:startRect window:window params:params];
}

@end

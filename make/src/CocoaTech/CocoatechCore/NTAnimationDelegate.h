//
//  NTAnimationDelegate.h
//  CocoatechCore
//
//  Created by Steve Gehrman on 1/23/09.
//  Copyright 2009 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTAnimationDelegate;

@protocol NTAnimationDelegateProtocol <NSObject>
- (NSView*)animationDelegateView:(NTAnimationDelegate*)delegate;
- (void)animationDelegateDidStart:(NTAnimationDelegate*)delegate;
- (void)animationDelegateDidStop:(NTAnimationDelegate*)delegate finished:(BOOL)flag;
@end

@interface NTAnimationDelegate : NSObject <CAAnimationDelegate>
{
	id<NTAnimationDelegateProtocol> __unsafe_unretained delegate;
	NSDictionary* animations;
}

@property (unsafe_unretained) id<NTAnimationDelegateProtocol> delegate;  // not retained, but clear delegate before releasing
@property (strong) NSDictionary* animations;

+ (NTAnimationDelegate*)frameDelegate:(id<NTAnimationDelegateProtocol>)theDelegate;
+ (NTAnimationDelegate*)boundsDelegate:(id<NTAnimationDelegateProtocol>)theDelegate;
- (void)clearDelegate;

@end

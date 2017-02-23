//
//  NTAnimations.m
//  CocoatechCore
//
//  Created by Steve Gehrman on Sat Aug 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NTAnimations.h"
#import "NTAnimationsWindow.h"

@interface NTAnimations ()
- (NTAnimationsWindow *)window;
- (void)setWindow:(NTAnimationsWindow *)theWindow;

+ (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame;
@end

@implementation NTAnimations

NTSINGLETON_INITIALIZE;
NTSINGLETONOBJECT_STORAGE;

- (id)init;
{
	self = [super init];

	[self window];  // create window now to make sure it's ready and visible when animations need to show
	
	return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setWindow:nil];
}

- (void)zoomIcon:(NSImage*)image atPoint:(NSPoint)globalPoint;
{	
    [[self window] zoomImage:image atPoint:globalPoint];
}

+ (void)shakeWindow:(NSWindow*)theWindow;
{
	[theWindow setAnimations:[NSDictionary dictionaryWithObject:[self shakeAnimation:[theWindow frame]] forKey:@"frameOrigin"]];
	[[theWindow animator] setFrameOrigin:[theWindow frame].origin];
}

+ (void)setupWindowFadeAnimation:(NSWindowController*)windowController;
{
	CAAnimation *anim = [CABasicAnimation animation];
	anim.duration = .12;

	[anim setDelegate:windowController];
	[windowController.window setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];	
}	

//---------------------------------------------------------- 
//  window 
//---------------------------------------------------------- 
- (NTAnimationsWindow *)window
{
	if (!mWindow)
		[self setWindow:[NTAnimationsWindow window]];
	
    return mWindow; 
}

- (void)setWindow:(NTAnimationsWindow *)theWindow
{
    if (mWindow != theWindow)
    {
        mWindow = theWindow;
    }
}

static NSInteger numberOfShakes = 4;
static CGFloat durationOfShake = 0.5;
static CGFloat vigourOfShake = 0.05;

+ (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame
{
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
	
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
	NSInteger index;
	for (index = 0; index < numberOfShakes; ++index)
	{
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
	}
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    return shakeAnimation;
}

@end

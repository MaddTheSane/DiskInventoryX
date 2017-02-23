//
//  NTAnimationsZoomView.h
//  CocoatechCore
//
//  Created by Steve Gehrman on 1/2/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTAnimationsZoomView : NSView <CAAnimationDelegate, CALayerDelegate>
{
	NSImage* image;
	CALayer* imageLayer;
	
	CAAnimation *transformAnimation;
	CAAnimation *opacityAnimation;
}

@property (strong) NSImage* image;
@property (strong) CALayer* imageLayer;
@property (strong) CAAnimation *transformAnimation;
@property (strong) CAAnimation *opacityAnimation;

+ (NTAnimationsZoomView*)view:(NSRect)frame;

- (void)animate;

@end


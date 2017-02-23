//
//  ZoomInfo.h
//  TreeMapView
//
//  Created by Tjark Derlien on 30.11.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZoomInfo : NSObject
{
	__strong NSImage *_image; //retained
	NSRect _rect;
	NSUInteger _zoomStepsLeft;
	CGFloat _leftStep, _topStep, _rightStep, _bottomStep;
	__unsafe_unretained id _delegate;
	SEL _delegateSelector;
	NSTimer *_timer;
}

- (instancetype) initWithImage: (NSImage*) image
					  delegate: (id) delegate
					  selector: (SEL) selector;

- (void) calculateZoomFromRect: (NSRect) startRect toRect: (NSRect) endRect;

@property (readonly, retain) NSImage *image;
@property (readonly) NSRect imageRect;

- (void) drawImage;

@property (readonly) BOOL hasFinished;

@end

//
//  NTSelectionGradient.h
//  CocoatechCore
//
//  Created by Steve Gehrman on 10/29/08.
//  Copyright 2008 Cocoatech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTGradientDraw;

@interface NTSelectionGradient : NSObject {
	NTGradientDraw* aquaGradient;
	NSColor* aquaLineColor;
	
	NTGradientDraw* graphiteGradient;
	NSColor* graphiteLineColor;

	NTGradientDraw* dimmedGradient;
	NSColor* dimmedLineColor;
}

@property (strong) NTGradientDraw* aquaGradient;
@property (strong) NSColor* aquaLineColor;
@property (strong) NTGradientDraw* graphiteGradient;
@property (strong) NSColor* graphiteLineColor;
@property (strong) NTGradientDraw* dimmedGradient;
@property (strong) NSColor* dimmedLineColor;

+ (NTSelectionGradient*)gradient;

- (void)drawGradientInRect:(NSRect)frame 
					dimmed:(BOOL)dimmed 
				   flipped:(BOOL)flipped;
@end

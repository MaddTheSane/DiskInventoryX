//
//  TMVCushionRenderer.h
//  Disk Accountant
//
//  Created by Doom on Sun Oct 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//
// The treemap colors all have the "brightness" BASE_BRIGHTNESS.
// I define brightness as a number from 0 to 3.0.
// RGB(0.5, 1, 0), for example, has a brightness of 2.5.
//
#define BASE_BRIGHTNESS 1.8

@interface TMVCushionRenderer : NSObject
{
    NSRect _rect;
    NSColor *_color;
    double _surface[4];
}

- (id) init;
- (id) initWithRect: (NSRect) rect;

- (NSRect) rect;
- (void) setRect: (NSRect) rect;

- (NSColor*) color;
- (void) setColor: (NSColor*) newColor;

- (double*) surface;
- (void) setSurface: (const double*) newsurface;

- (void) addRidgeByHeightFactor: (double) heightFactor;

- (void) renderCushionInBitmap: (NSBitmapImageRep*) bitmap;

+ (void) normalizeColorRed: (float*) red green: (float*) green blue: (float*) blue;
+ (NSColor*) normalizeColor: (NSColor*) color;

@end

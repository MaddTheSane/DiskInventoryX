//
//  TMVCushionRenderer.h
//  Disk Accountant
//
//  Created by Tjark Derlien on Sun Oct 12 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import <Foundation/Foundation.h>

//
// The treemap colors all have the "brightness" BASE_BRIGHTNESS.
// I define brightness as a number from 0 to 3.0.
// RGB(0.5, 1, 0), for example, has a brightness of 2.5.
//
#define BASE_BRIGHTNESS 1.8f

@interface TMVCushionRenderer : NSObject
{
    NSRect _rect;
    NSColor *_color;
    float _surface[4];
}

- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithRect: (NSRect) rect;

@property NSRect rect;
@property (strong) NSColor *color;

- (float*) surface NS_RETURNS_INNER_POINTER;
- (void) setSurface: (const float*) newsurface;

- (void) addRidgeByHeightFactor: (CGFloat) heightFactor;

- (void) renderCushionInBitmap: (NSBitmapImageRep*) bitmap;
- (void) renderCushionInBitmapGeneric: (NSBitmapImageRep*) bitmap;
- (void) renderCushionInBitmapPPC603: (NSBitmapImageRep*) bitmap; //PowerPC optimzed version (603+)

+ (void) normalizeColorRed: (CGFloat*) red green: (CGFloat*) green blue: (CGFloat*) blue;
+ (NSColor*) normalizeColor: (NSColor*) color;

@end

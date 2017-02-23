//
//  ImageAndTextCell.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//

//This class is taken from the AppKit example "DragNDropoutlineView".
//(installed with the Apple dev tools)

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell {
@private
    NSImage	*_image;
}

@property (retain) NSImage *image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end
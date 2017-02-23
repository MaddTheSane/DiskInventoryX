//
//  FilesOutlineViewNameCell.h
//  Disk Accountant
//
//  Created by Doom on Tue Oct 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

//The implementations of the methods of this category are taken from the
//CocoaTechFoundation framework of Path Finder 3 (Open Source)

#import <Foundation/Foundation.h>

@interface NSImage(ScaleExtension)

- (NSImage*)sizeIcon:(int)size;
- (NSBitmapImageRep*)bitmapImageRepForSize:(int)size;

@end

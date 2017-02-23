//
//  FilesOutlineViewNameCell.m
//  Disk Accountant
//
//  Created by Doom on Tue Oct 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSImage-ScaleExtension.h"

//The implementations of the methods of this category are taken from the
//CocoaTechFoundation framework of Path Finder 3 (Open Source)

@interface NSImage(ScaleExtension_Private)

+ (NSImage*)tmpImage:(int)size;

@end

@implementation NSImage(ScaleExtension)

// find the right representation and create a new autoreleased NSImage
// we don't want to change the size of the original
- (NSImage*)sizeIcon:(int)size;
{
    NSImage* sizedImage = [[[NSImage alloc] initWithSize:NSMakeSize(size, size)] autorelease];
    NSArray* reps = [self representations];
    int i, cnt = [reps count];
    NSImageRep *rep;
    BOOL found = NO;

    for (i=0;i<cnt;i++)
    {
        rep = [reps objectAtIndex:i];

        if ([rep size].width == size)
        {
            found = YES;
            // a rep can't exist in more than one image, so copy it
            rep = [[rep copy] autorelease];
            [sizedImage addRepresentation:rep];
            break;
        }
    }

    // the size wasn't found, so lets draw the image scaled inside the correct size rectangle
    if (!found)
    {
        NSRect destRect = NSMakeRect(0, 0, size, size);
        NSRect srcRect;
        NSGraphicsContext* context;
        NSImageInterpolation savedInterpolation;
        NSImageRep* closestRep=nil;

        // need to find the closest size for our source rectangle
        for (i=0;i<cnt;i++)
        {
            rep = [reps objectAtIndex:i];

            if (closestRep)
            {
                // is this a closer match?
                if (abs([rep size].width - size) < abs([closestRep size].width - size))
                {
                    // is it bigger than the size passed in?
                    if ([rep size].width > size)
                        closestRep = rep;
                }
            }
            else
                closestRep = rep;
        }

        srcRect.origin = NSMakePoint(0, 0);
        srcRect.size = [closestRep size];

        [sizedImage lockFocus];

        context = [NSGraphicsContext currentContext];
        savedInterpolation = [context imageInterpolation];

        [[NSColor clearColor] set];
        NSRectFill( destRect );
        
        [context setImageInterpolation:NSImageInterpolationHigh];
        [closestRep drawInRect:destRect];

        [context setImageInterpolation:savedInterpolation];

        [sizedImage unlockFocus];
    }

    return sizedImage;
}

- (NSBitmapImageRep*)bitmapImageRepForSize:(int)size
{
    NSArray* reps = [self representations];
    int i, cnt = [reps count];
    NSBitmapImageRep *rep;
    NSRect destRect = NSMakeRect(0, 0, size, size);
    NSRect srcRect;
    NSImageRep* closestRep=nil;

    for (i=0;i<cnt;i++)
    {
        rep = [reps objectAtIndex:i];

        if ([rep size].width == size && [rep isMemberOfClass:[NSBitmapImageRep class]])
        {
            // a rep can't exist in more than one image, so copy it
            return [[rep copy] autorelease];
        }
    }

    // need to find the closest size for our source rectangle
    for (i=0;i<cnt;i++)
    {
        rep = [reps objectAtIndex:i];

        if ([rep size].width == size)
        {
            closestRep = rep;
            break;
        }
        else
        {
            if (closestRep)
            {
                // is this a closer match?
                if (abs([rep size].width - size) < abs([closestRep size].width - size))
                {
                    // is it bigger than the size passed in?
                    if ([rep size].width > size)
                        closestRep = rep;
                }
            }
            else
                closestRep = rep;
        }
    }

    srcRect.origin = NSMakePoint(0, 0);
    srcRect.size = [closestRep size];

    NSImage* tmpImage = [NSImage tmpImage:size];
    [tmpImage lockFocus];

    // clear out the offscreen
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0,0,size,size));

    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [closestRep drawInRect:destRect];

    rep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0,0,size,size)] autorelease];

    [tmpImage unlockFocus];

    return rep;
}

@end

@implementation NSImage (ScaleExtension_Private)

+ (NSImage*)tmpImage:(int)size
{
    static NSImage* sTmpImage = nil;

    if (!sTmpImage)
        sTmpImage = [[NSImage alloc] initWithSize:NSMakeSize(32, 32)];

    if (size > [sTmpImage size].width)
    {
        [sTmpImage release];
        sTmpImage = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
    }

    return sTmpImage;
}

@end

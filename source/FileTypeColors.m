//
//  FileTypeColors.m
//  DiskAccountant
//
//  Created by Doom on Sun Oct 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "FileTypeColors.h"
#import "TMVCushionRenderer.h"

@implementation FileTypeColors

+ (FileTypeColors*) instance
{
    static FileTypeColors * _instance = nil;

    if ( _instance == nil )
        _instance = [[FileTypeColors alloc] init];

    return _instance;
}

- (id) init
{
    self = [super init];
    
    unsigned i;
    
    self = [super init];

    _colors = [[NSMutableDictionary alloc] init];

#define COLOR(r,g,b) [NSColor colorWithCalibratedRed: r green: g blue: b alpha: 1.0]
    
    _predefinedColors = [[NSMutableArray alloc] initWithObjects:
        COLOR(0, 0, 1),
        COLOR(1, 0, 0),
        COLOR(0, 1, 0),
        COLOR(0, 1, 1),
        COLOR(1, 0, 1),
        COLOR(1, 1, 0),
        COLOR(0.58, 0.58, 1),
        COLOR(1, 0.58, 0.58),
        COLOR(0.58, 1, 0.58),
        COLOR(0.58, 1, 1),
        COLOR(1, 0.58, 1),
        COLOR(1, 1, 0.58),
        nil];

#undef COLOR

    for ( i = 0; i < [_predefinedColors count]; i++ )
    {
        NSColor *color = [_predefinedColors objectAtIndex: i];
        [_predefinedColors replaceObjectAtIndex: i withObject: [TMVCushionRenderer normalizeColor: color]];
    }
    
    return self;
}

- (void) dealloc
{
    [_predefinedColors release];
    [_colors release];

    [super dealloc];
}

- (NSColor *) colorForItem: (FSItem*) item
{
    return [self colorForKind: [item kindName]];
}

- (NSColor *) colorForKind: (NSString*) kind
{
    NSColor *color = [_colors objectForKey: kind];

    if ( color == nil )
    {
        if ( [_predefinedColors count] > 0 )
        {
            color = [_predefinedColors objectAtIndex: 0];

            [_colors setObject: color forKey: kind];
            
            [_predefinedColors removeObjectAtIndex: 0];
        }
        else
        {
            float rgbComponent = 0.6 + [_colors count] * 0.1;
            
            if ( rgbComponent > 0.9 )
                rgbComponent = 0.9;

            color = [NSColor colorWithCalibratedRed: rgbComponent green: rgbComponent blue: rgbComponent alpha: 1.0];

            color = [TMVCushionRenderer normalizeColor: color];

            [_colors setObject: color forKey: kind];
        }
    }

    return color;
}

@end

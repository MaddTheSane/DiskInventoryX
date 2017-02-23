//
//  NTFont.h
//  CocoatechCore
//
//  Created by Steve Gehrman on Fri Dec 28 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTFont : NSObject <NSCoding>
{
    NSFont* normal;
    NSFont* bold;
    NSFont* italic;
    NSFont* boldItalic;
}

@property (strong, nonatomic) NSFont* normal;
@property (strong, nonatomic) NSFont* bold;
@property (strong, nonatomic) NSFont* italic;
@property (strong, nonatomic) NSFont* boldItalic;

+ (instancetype)fontWithFont:(NSFont*)font;

// Helvetica Bold - 12pt
- (NSString*)displayString;

@end

//
//  NTFontButton.h
//  CocoatechCore
//
//  Created by Steve Gehrman on Sun Dec 29 2002.
//  Copyright (c) 2002 CocoaTech. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NTFont;

@interface NTFontButton : NSButton
{
    IBOutlet id __unsafe_unretained delegate;

    NTFont* displayedFont;
}

@property (unsafe_unretained) IBOutlet id delegate;  // not retained
@property (strong) NTFont* displayedFont;

- (IBAction)setFontUsingFontPanel:(id)sender;

@end

@interface NSObject (NTFontButtonDelegate)
- (void)fontButton:(NTFontButton *)fontButton didChangeToFont:(NTFont *)newFont;
@end


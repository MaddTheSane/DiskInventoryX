//
//  NTTemplateButton.h
//  CocoatechCore
//
//  Created by Steve Gehrman on 4/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NTTemplateButton : NSButton
{
	BOOL mouseOver;
	NSMenu* menu;
	NSTrackingArea* trackingArea;
	
	NSString* mouseDownNotification;  // if set, will post notification on mouseDown, useful for setting up first responder before action is triggered
}

@property (nonatomic, strong) NSString* mouseDownNotification;
@property (nonatomic, strong) NSMenu* menu;

+ (NTTemplateButton*)button:(NSImage*)image; // toggleButton == NO by default
+ (NTTemplateButton*)button:(NSImage*)image toggleButton:(BOOL)toggleButton;

- (NSSize)size;
@end

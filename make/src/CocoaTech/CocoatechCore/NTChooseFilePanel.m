//
//  NTChooseFilePanel.m
//  CocoatechCore
//
//  Created by sgehrman on Mon Aug 27 2001.
//  Copyright (c) 2001 CocoaTech. All rights reserved.
//

#import "NTChooseFilePanel.h"
#import "NSSavePanel-NTExtensions.h"
#import "NTUtilities.h"

@interface NTChooseFilePanel (Private)
- (void)startPanel:(NSString*)startPath window:(NSWindow*)window fileType:(ChooseFileTypeEnum)fileType showInvisibleFiles:(BOOL)showInvisibleFiles;
@end

@interface NTChooseFilePanel (hidden)
- (void)setPath:(NSString *)thePath;
- (void)setUserClickedOK:(BOOL)flag;

- (SEL)selector;
- (void)setSelector:(SEL)theSelector;

- (id)target;
- (void)setTarget:(id)theTarget;
@end

@implementation NTChooseFilePanel

- (id)initWithTarget:(id)target selector:(SEL)inSelector;
{
    self = [super init];

    [self setSelector:inSelector];
    [self setTarget:target];

    return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
    [self setPath:nil];
    [self setTarget:nil];
}

+ (void)openFile:(NSString*)startPath window:(NSWindow*)window target:(id)target selector:(SEL)inSelector fileType:(ChooseFileTypeEnum)fileType;
{
	[self openFile:startPath window:window target:target selector:inSelector fileType:fileType showInvisibleFiles:NO];
}

+ (void)openFile:(NSString*)startPath window:(NSWindow*)window target:(id)target selector:(SEL)inSelector fileType:(ChooseFileTypeEnum)fileType showInvisibleFiles:(BOOL)showInvisibleFiles;
{
    NTChooseFilePanel *panel = [[NTChooseFilePanel alloc] initWithTarget:target selector:inSelector];

    [panel startPanel:startPath window:window fileType:fileType showInvisibleFiles:showInvisibleFiles];
	
	LEAKOK(panel);
}

//---------------------------------------------------------- 
//  path 
//---------------------------------------------------------- 
- (NSString *)path
{
    return mPath; 
}

- (void)setPath:(NSString *)thePath
{
    if (mPath != thePath)
    {
        mPath = thePath;
    }
}

//---------------------------------------------------------- 
//  selector 
//---------------------------------------------------------- 
- (SEL)selector
{
    return mSelector;
}

- (void)setSelector:(SEL)theSelector
{
    mSelector = theSelector;
}

//---------------------------------------------------------- 
//  target 
//---------------------------------------------------------- 
- (id)target
{
    return mTarget; 
}

- (void)setTarget:(id)theTarget
{
    if (mTarget != theTarget)
    {
        mTarget = theTarget;
    }
}

//---------------------------------------------------------- 
//  userClickedOK 
//---------------------------------------------------------- 
- (BOOL)userClickedOK
{
    return mUserClickedOK;
}

- (void)setUserClickedOK:(BOOL)flag
{
    mUserClickedOK = flag;
}

@end

@implementation NTChooseFilePanel (Private)

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(__unused void *)contextInfo
{
    if (returnCode == NSOKButton)
    {
		[self setUserClickedOK:YES];
        [self setPath:[[sheet URL] path]];
	}
	
	[sheet orderOut:self];
	
	// send out the selector
	[[self target] performSelector:[self selector] withObject:self];
	
    //[self autorelease];
}

- (void)startPanel:(NSString*)startPath window:(NSWindow*)window fileType:(ChooseFileTypeEnum)fileType showInvisibleFiles:(BOOL)showInvisibleFiles;
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseDirectories:(fileType == kFilesAndFoldersType) ? YES : NO];
    [op setCanChooseFiles:YES];
    [op setAllowsMultipleSelection:NO];
	[op setShowsHiddenFiles:showInvisibleFiles];
	if (startPath) {
		op.directoryURL = [NSURL fileURLWithPath:startPath];
	}
	
    if (fileType == kApplicationFileType)
        [op setPrompt:[NTLocalizedString localize:@"Choose Application" table:@"CocoaTechBase"]];
    else if (fileType == kImageFileType)
        [op setPrompt:[NTLocalizedString localize:@"Choose Image" table:@"CocoaTechBase"]];
    else if (fileType == kGenericFileType || fileType == kTextFileType || fileType == kFilesAndFoldersType)
        [op setPrompt:[NTLocalizedString localize:@"Choose File" table:@"CocoaTechBase"]];
	
    // window is not wide enough, the buttons overlap
    [op setMinSize:NSMakeSize(480, [op minSize].height)];
	
	if (window) {
		[op beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
			[self openPanelDidEnd:op returnCode:result contextInfo:NULL];
		}];
	} else
    {
        NSInteger result = [op runModal];
        if (result == NSOKButton)
        {
			[self setUserClickedOK:YES];
			[self setPath:[[op URL] path]];
		}
		
		// must hide the sheet before we send out the action, otherwise our window wont get the action
		[op orderOut:nil];
		
		// send out the selector
		[[self target] performSelector:[self selector] withObject:self];
		
        //[self autorelease];
    }
}

@end



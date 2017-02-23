//
//  MyDocumentController.m
//  Disk Accountant
//
//  Created by Doom on Wed Oct 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MyDocumentController.h"

//global variable which enables/disables logging
BOOL g_EnableLogging;


@implementation MyDocumentController

- (void) applicationWillFinishLaunching: (NSNotification*) notification
{
    //verify that our custom DocumentController is in use 
    NSAssert( [[NSDocumentController sharedDocumentController] isKindOfClass: [MyDocumentController class]], @"the shared DocumentController is not our custom class!" );
	
	g_EnableLogging = [[NSUserDefaults standardUserDefaults] boolForKey: @"EnableLogging"];
}


- (int) runModalOpenPanel: (NSOpenPanel*) openPanel forTypes: (NSArray*) extensions
{
    //we want the user to choose a directory (including packages)
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];
    [openPanel setTreatsFilePackagesAsDirectories: YES];

    return [openPanel runModalForTypes: nil];
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication*) sender
{
    //we don't want any untitled document as we need an existing folder
    return NO;
}

- (id)makeDocumentWithContentsOfFile:(NSString *)fileName ofType:(NSString *)docType
{
	//check whether "fileName" is a folder
	NSDictionary *attribs = [[NSFileManager defaultManager] fileAttributesAtPath: fileName traverseLink: NO];
    if ( attribs != nil )
	{
		NSString *type = [attribs fileType];
		if ( type != nil && [type isEqualToString: NSFileTypeDirectory] )
			return [super makeDocumentWithContentsOfFile:fileName ofType: @"Folder"];
	}
	
	return nil;
}

- (id)openDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)flag
{
	return [super openDocumentWithContentsOfFile: fileName display: flag];
}

- (NSString *)typeFromFileExtension:(NSString *)fileExtensionOrHFSFileType
{
	OSType type = NSHFSTypeCodeFromFileType(fileExtensionOrHFSFileType);
	if ( type == 0 )
		return @"Folder";
	else	
		return [super typeFromFileExtension: fileExtensionOrHFSFileType];
}

@end

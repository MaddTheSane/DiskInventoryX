//
//  NTFileDesc-AccessExtensions.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 03.10.04.
//  Copyright 2004 Tjark Derlien. All rights reserved.
//

#import "NTFileDesc-AccessExtensions.h"
#import <CocoatechFile/NTFileDesc.h>
#import <CocoatechFile/NTFileDescData.h>

@implementation NTFileDesc(AccessExtensions)

- (NTFSRefObject*) fsRefObject
{
	return FSRefObject;
}

//#if 0
- (void) setKindString: (NSString*) kindString
{
	/*
	[_lock lock];
	
	[kindString retain];
	[_kindString release];
	_kindString = kindString;
	
	_bools.kindString_initialized = YES;
	
	[_lock unlock];*/
	[[self cache] setKind:kindString];
}

- (BOOL) isKindStringSet
{
	//- (BOOL)kind_initialized:(NSString**)outValue;
	return [[self cache] kind_initialized:NULL];
	//return _bools.kindString_initialized;
}

//NTFileDesc calls "FSGetTotalForkSizes(..)" to get the size of a file and
//to get a folder's size, you need caluculate it by youself and then call [fileDesc setFolderSize:].
//(PathFinders spawns a thread to calculate a folder's size in the background)
//We calculate the size during the folder traversal so we don't need the thread nor
//"FSGetTotalForkSizes(..)".
//(as we just add the logical sizes of the data and resource forks to get a file's size)
- (void) setSize: (UInt64) size
{
	[[self cache] setFileSize:size];
}
//#endif

@end

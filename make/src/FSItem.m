//
//  FSItem.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "FSItem.h"
#import <CocoaTechFoundation/NTFileDesc.h>
#import <CocoaTechFoundation/NTFSRefObject.h>
#import <NTFileDesc-AccessExtensions.h>
#import "NTFSRefObject-AccessExtensions.h"
#import <OmniFoundation/NSArray-OFExtensions.h>

//for debugging and logging purposes
unsigned g_fileCount;
unsigned g_folderCount;
static unsigned g_packageCheckCount = 0;

//global cache for kind names
NSMutableDictionary *g_kindNameDictionary = nil;

//exceptions
NSString* FSItemLoadingCanceledException = @"FSItemLoadingCanceledException";
NSString* FSItemLoadingFailedException = @"FSItemLoadingFailedException";

//this define and typedef is needed for bulk fetching
#define kRequestCountPerIteration	( (4096 * 16) / (sizeof(FSCatalogInfo) + sizeof(FSRef) + sizeof(HFSUniStr255) + 4) )
#define kCatalogInfoBitmapBulk (kFSCatInfoNodeFlags | kFSCatInfoVolume | kFSCatInfoParentDirID | kFSCatInfoFinderInfo | kFSCatInfoDataSizes | kFSCatInfoRsrcSizes | kFSCatInfoPermissions| kFSCatInfoAttrMod | kFSCatInfoContentMod)

static struct _BulkCatalogInfoRec {
    FSCatalogInfo catalogInfoArray[kRequestCountPerIteration];
	FSRef fsRefArray[kRequestCountPerIteration];
	HFSUniStr255 namesArray[kRequestCountPerIteration];
	struct _BulkCatalogInfoRec *nextRecord;
} g_BulkCatalogInfo;
//typedef struct _BulkCatalogInfoRec BulkCatalogInfoRec;

//================ interface FSItem(Private) ======================================================

@interface FSItem(Private)

- (id) initWithName: (NSString *) name
			 parent: (FSItem*) parent
	  setKindString: (BOOL) setKindString
  ignoreCreatorCode: (BOOL) ignoreCreatorCode
			  fsRef: (FSRef*) fsRef
		catalogInfo: (FSCatalogInfo*) catalogInfo;

- (void) setParent: (FSItem*) parent;

- (NSComparisonResult) compareSizeDescendingly: (FSItem*) other; //compares sizes

- (void) loadChildrenAndSetKindStrings: (BOOL) setKindStrings ignoreCreatorCode: (BOOL) ignoreCreatorCode;

- (void) setSize: (NSNumber*) size;
- (void) setSizeValue: (unsigned long long) size;

@end

//================ implementation FSItem ======================================================

@implementation FSItem

+ (void) initialize
{
	//instantiate the dictionaries for global kind names cache and for our notifications user info
	g_kindNameDictionary = [[NSMutableDictionary alloc] init];
}

- (id) initWithPath: (NSString *) path
{
    self = [super init];
	
	_type = FileFolderItem;
	
    g_fileCount = 0;
    g_folderCount = 0;
	
	_fileDesc = [[NTFileDesc alloc] initWithPath: path];
	
    _parent = nil; //we are the root item
	
    NSAssert1( [self isFolder], @"root item is no directory: %@", path );
    
    return self;
}

- (id) initAsOtherSpaceItemForParent: (FSItem*) parent
{
    self = [super init];
	
	_type = OtherSpaceItem;
	
	_parent = parent; //weak reference
	
	NSString* hashString = [[parent path] stringByAppendingString: @"/OtherSpace"];
	_hash = [hashString hash];
	
	[self recalculateSize: NO];
	
	return self;
}

- (id) initAsFreeSpaceItemForParent: (FSItem*) parent
{
    self = [super init];
	
	_type = FreeSpaceItem;
	
	_parent = parent;
	
	NSString* hashString = [[parent path] stringByAppendingString: @"/FreeSpace"];
	_hash = [hashString hash];
	
	[self recalculateSize: NO];
	
	return self;
}

- (id) delegate
{
	return [self root]->_delegate;
}

- (void) setDelegate: (id) delegate
{
	_delegate = delegate; //no retain
}

- (void) dealloc
{
    [_childs release];
    [_fileDesc release];
	[_size release];
	[_icons release];
    
    //_parent no release!
	
    [super dealloc];
}

- (FSItemType) type
{
	return _type;
}

- (BOOL) isSpecialItem
{
	return [self type] != FileFolderItem;
}

- (NTFileDesc *) fileDesc
{
	if ( ![self isSpecialItem] )
		return _fileDesc;
	else
		return [[self root] fileDesc];
}

- (void) setFileDesc: (NTFileDesc*) desc
{
	NSAssert( ![self isSpecialItem], @"free and other space items don't habe a NTFileDesc object");
	
	[desc retain];
	[_fileDesc release];
	_fileDesc = desc;
}

- (unsigned) hash
{
	if ( _hash == 0 )
		_hash = [[self path] hash];
	
    return _hash;
}

- (BOOL) isEqual: (id) object
{
    FSItem *item = object;
    return [item isKindOfClass: [FSItem class]]
		&& [self type] == [item type]
		&& [[self fileDesc] isEqual: [item fileDesc]];
}

- (NSString *) description
{
	switch ( [self type] )
	{
		case FileFolderItem:
			return [[self fileDesc] description];
		case FreeSpaceItem:
			return @"FreeSpaceItem";
		case OtherSpaceItem:
			return @"OtherSpaceItem";
	}
	
	NSAssert( NO, @"unknown item type" );
	return @"";		
}

- (FSItem*) parent
{
    return _parent;
}

- (FSItem*) root
{
    if ( [self isRoot] )
        return self;
    else
        return [[self parent] root];
}

- (BOOL) isRoot
{
    return _parent == nil;
}

- (BOOL) isFolder
{
	if ( ![self isSpecialItem] )
	{
		return [[self fileDesc] isDirectory];
	}
	else
		return NO;
}

- (BOOL) isPackage
{
	if ( [self type] == FileFolderItem )
		return [[self fileDesc] isPackage];
	else
		return NO;
}

- (BOOL)isAlias
{
	if ( ![self isSpecialItem] )
	{
		//we don't use NTFileDesc.isAlias as it also return YES for a PathFinderAlias:
		//return ([desc isSymbolicLink] || [desc isCarbonAlias] || [self isPathFinderAlias])
		NTFileDesc *desc = [self fileDesc];
		return ([desc isSymbolicLink] || [desc isCarbonAlias]);
	}
	else
		return NO;
}

- (BOOL) exists
{
	//NSTFileDesc.exists checks it's FSRef and it's path, but the path might have been generated
	//from the FSRef. But as we want to know if the file still exists at the place at the
	//time we searched the file, we have to check the path that we store.
	return [_fileDesc exists] && [NTFileUtilities validPath:[self path]];
}

- (NSImage*) iconWithSize: (unsigned) iconSize
{
	//items for free space and other space don't have an icon
	if ( [self isSpecialItem] )
		return nil;
	
	if ( _icons == nil )
		_icons = [[NSMutableDictionary alloc] init];
	
	NSNumber *key = [NSNumber numberWithUnsignedInt: iconSize];
	NSImage *icon = [_icons objectForKey: key];
	if ( icon == nil )
	{
		icon = [NSImage imageForDesc:[self fileDesc] size: iconSize];
		if ( icon == nil )
			icon = (id) [NSNull null];
		
		[_icons setObject: icon forKey: key];
	}
	
	return (icon == (id)[NSNull null]) ? nil : icon;
}

- (NSEnumerator *) childEnumerator
{
	if ( ![self isSpecialItem] )
		return [_childs objectEnumerator];
	else
		return nil;
}

- (FSItem*) childAtIndex: (unsigned) index
{
	if ( ![self isSpecialItem] )
		return [_childs objectAtIndex: index];
	else
		return nil;
}

- (unsigned) childCount
{
	if ( ![self isSpecialItem] )
		return [_childs count];
	else
		return 0;
}

- (void) removeChild: (FSItem*) child
{
	NSAssert( ![self isSpecialItem], @"removeChild is illegal call for special item" );
	
	unsigned index = [_childs indexOfObjectIdenticalTo: child];
	if ( index != NSNotFound )
	{
		[self setSizeValue: [self sizeValue] - [child sizeValue]];
		
		[_childs removeObjectAtIndex: index];
	}
}

- (void) insertChild: (FSItem*) newChild
{
	[newChild setParent: self];
	
	//find insert position (sorted by size)
	unsigned i;
	for ( i = 0; i < [self childCount] && [[self childAtIndex: i] sizeValue] > [newChild sizeValue]; i++ );
	
	if ( i >= [self childCount] )
		[_childs addObject: newChild];
	else
		[_childs insertObject: newChild atIndex: i];
	
	[self setSizeValue: [self sizeValue] + [newChild sizeValue]];
}

- (void) replaceChild: (FSItem*) oldChild withItem: (FSItem*) newChild;
{
	if ( oldChild != newChild )
	{
		[self removeChild: oldChild];
		[self insertChild: newChild];
	}
}

- (NSNumber*) size
{
	if ( _size == nil )
		_size = [[NSNumber alloc] initWithUnsignedLongLong: [[self fileDesc] size]];
	
    return _size;
}

- (unsigned long long) sizeValue
{
	//if this is a special item, we don't have our own NTFileDesc object
	//(the size is just stored as a NSNumber)
	if ( [self isSpecialItem] )
		return [_size unsignedLongLongValue];
	else
		return [_fileDesc size];
}

//reloads everything
- (BOOL) refresh
{
	//_hash remains unchanged as it depends on the path (which also remains unchanged)
	
	if ( [self isSpecialItem] )
	{
		[self recalculateSize: NO];
	}
	else
	{
		if ( ![self exists] )
			return NO;
		
		//remember path as we will delete the NTFSRefObject which holds the path
		NSString *myPath = [[[self path] retain] autorelease];

		[_fileDesc autorelease];
		_fileDesc = [[_fileDesc newDesc] retain];
		
		//set the path in the new NTFSRefObject
		[[_fileDesc fsRefObject] setPath: myPath];
		
		[_size release];
		_size = nil;
		
		[_icons release];
		_icons = nil;
		
		[_childs release];
		_childs = nil;
		
		//will calculate our size (if this is a file NTFileDesc knows the size)
		if ( [self isFolder] )
			[self loadChildren];
	}
	
	return YES;
}

- (void) recalculateSize: (BOOL) usePhysicalSize
{
	unsigned long long size = 0;
	
	switch ( [self type] )
	{
		case FileFolderItem:
			if ( [self isFolder] )
			{
				unsigned i = [_childs count];
				while ( i-- )
				{
					FSItem *child = [_childs objectAtIndex: i];
					
					[child recalculateSize: usePhysicalSize];
						 
					size += [child sizeValue];
				}
				[_childs sortUsingSelector: @selector(compareSizeDescendingly:)];
			}
			else
			{
				//File
				NTFSRefObject *fsRefObject = [_fileDesc fsRefObject];
				if ( usePhysicalSize )
					size = [fsRefObject rsrcForkPhysicalSize] + [fsRefObject dataForkPhysicalSize];
				else
					size = [fsRefObject rsrcForkSize] + [fsRefObject dataForkSize];
			}
			break;
			
		case FreeSpaceItem:
			size = [NTFileDesc volumeFreeBytes: [self fileDesc]];
			break;
			
		case OtherSpaceItem:
			//the root item must has finished calculating it's size, otherwise this doesn't work
			size = [NTFileDesc volumeTotalBytes: [self fileDesc]]
						- [[self root] sizeValue]
						- [NTFileDesc volumeFreeBytes: [self fileDesc]];
			break;
	}
	
	[self setSizeValue: size];
}

//get display string for kind ("Application", "Simple Text Document", ...)
- (NSString *) kindName
{
	if ( ![self isSpecialItem] )
	{
		NTFileDesc *fileDesc = [self fileDesc];
		
		if ( ![fileDesc isKindStringSet] )
			[self setKindString];
		
		return [fileDesc kindString];
	}
	else
		return @"";
}

- (void) setKindString
{
	BOOL ignoreCreatorCode = NO;
	
	id delegate = [self delegate];
	if ( [delegate respondsToSelector: @selector(fsItemShouldIgnoreCreatorCode:)] )
		ignoreCreatorCode = [delegate fsItemShouldIgnoreCreatorCode: self];
	
	[self setKindStringIgnoringCreatorCode: ignoreCreatorCode includeChilds: NO];
}

//determines the kind of the file/folder as it is shown in the Finder's get info dialog.
//This routine tries to associate certain file criteria (type, creator, extension, ..)
//with the kind names so it can determine the kind name for similar files without asking
//the finder again and again.
- (void) setKindStringIgnoringCreatorCode: (BOOL) ignoreCreatorCode
							includeChilds: (BOOL) includeChilds
{
	NTFileDesc *fileDesc = [self fileDesc];
	id kindNameKey;
	
	OSType type = [fileDesc type];
	OSType creator = [fileDesc creator];
	NSString* extension = [fileDesc extension];
	
	if ( [extension length] == 0 ) 
		extension = nil;

	if ( ignoreCreatorCode )
	{
		//if no type code nor extension exists, we keep the creator code
		if ( type != kLSUnknownType || extension != nil )
			creator = kLSUnknownCreator;
	}
	
	BOOL askLSCopyKindStringForTypeInfo = NO; //will be set to YES if file has type, creator or extension
	
	if ( [fileDesc isVolume] )
		kindNameKey = @".Volume";
	else if ( [self isAlias] )
		kindNameKey = @".Alias";
	else if (type != kLSUnknownType || creator != kLSUnknownCreator)
	{
		askLSCopyKindStringForTypeInfo = YES;
		kindNameKey = [[NSMutableString alloc] init];
		
		if (type != kLSUnknownType)
		{
			NSString *typeString = [[NSString alloc] initWithBytes:&type length:sizeof(OSType) encoding:NSMacOSRomanStringEncoding];
			[kindNameKey appendFormat:@"T:%@ ", typeString];
			[typeString release];
		}
		if (creator != kLSUnknownCreator)
		{
			NSString *creatorString = [[NSString alloc] initWithBytes:&creator length:sizeof(OSType) encoding:NSMacOSRomanStringEncoding];
			[kindNameKey appendFormat:@"C:%@ ", creatorString];
			[creatorString release];
		}
		
		if (extension)
			[kindNameKey appendString: extension];
	}
	else if ( [fileDesc isDirectory] && ( extension == nil || ![fileDesc isPackage] ) ) //regular folder (no package)
		kindNameKey = @".Folder";
	else if ( extension != nil )
	{
		askLSCopyKindStringForTypeInfo = YES;
		kindNameKey = [extension retain];
	}
	else if ( [fileDesc isExecutableBitSet] )
		kindNameKey = @".UnixExecutable";
	else
		kindNameKey = @".unknown";
	
	if ( g_kindNameDictionary == nil )
		g_kindNameDictionary = [[NSMutableDictionary alloc] init];
	
	NSString *kindName = [g_kindNameDictionary objectForKey: kindNameKey];
	
	if ( kindName != nil )
		[[self fileDesc] setKindString: kindName];
	else
	{
		if ( askLSCopyKindStringForTypeInfo )
			LSCopyKindStringForTypeInfo( type, creator, (CFStringRef)extension, (CFStringRef*) &kindName);	// kindName is retained
		
		if ( kindName == nil )
			kindName = [[fileDesc kindString] retain];
		
		if ( kindName != nil )
		{
			//remember kind name for similar files
			[g_kindNameDictionary setObject: kindName forKey: kindNameKey];
			
			[fileDesc setKindString: kindName];
			[kindName release];
		}
		else
			LOG( @"couldn't get kind name for '%@'; will use default kind", [self path]);
	}
	
	[kindNameKey release];
	
	//let our childs do the same
	if ( includeChilds && [self isFolder] )
	{
		unsigned i = [self childCount];
		while ( i-- )
			[[self childAtIndex: i] setKindStringIgnoringCreatorCode: ignoreCreatorCode includeChilds: YES];
	}
}

- (NSString *) name
{
	switch ( [self type] )
	{
		case FileFolderItem:
			return [[self fileDesc] name];
		case FreeSpaceItem:
			return @"FreeSpaceItem";
		case OtherSpaceItem:
			return @"OtherSpaceItem";
	}
	
	NSAssert( NO, @"unknown item type" );
	return @"";
}

- (NSString *) path
{
	if ( ![self isSpecialItem] )
	{
		NTFSRefObject *fsRefObject = [[self fileDesc] fsRefObject];
		if ( ![fsRefObject isPathSet] )
		{
			NSAssert( ![self isRoot], @"root item's path must be set initially" );
			//parent path + "/" + name
			NSString *path = [[[self parent] path] stringByAppendingPathComponent: [self name]];
			[fsRefObject setPath: path];
		}
		
		return [[fsRefObject ntPath] path];
	}
	else
		return [self name];
}

- (NSString *) folderName
{
	if ( ![self isSpecialItem] )
	{
		FSItem *parent = [self parent];
		if ( parent == nil )
			return [[self path] stringByDeletingLastPathComponent];
		else
			return [parent path];
	}
	else
		return @"";
}

//display string for name (with or without extension; localized file names)
- (NSString *) displayName
{
	switch ( [self type] )
	{
		case FileFolderItem:
			return [[self fileDesc] displayName];
		case FreeSpaceItem:
			return NSLocalizedString( @"free space on drive", @"" );
		case OtherSpaceItem:
			return NSLocalizedString( @"space occupied by other files and folders", @"" );
	}
	
	NSAssert( NO, @"unknown item type" );
	return @"";
}

- (NSString *) displayFolderName
{
	if ( ![self isSpecialItem] )
	{
		FSItem *parent = [self parent];
		if ( parent != nil )
			return [[parent displayFolderName] stringByAppendingPathComponent: [parent displayName]];
		else
			return @"";
	}
	else
		return @"";
}

- (NSString *) displayPath
{
	if ( ![self isSpecialItem] )
		return [[self displayFolderName] stringByAppendingPathComponent: [self displayName]];
	else
		return [self displayName];
}

//if this is a folder, load all containing files (recursively)
- (void) loadChildren
{
	BOOL ignoreCreatorCode = NO;
	
	id delegate = [self delegate];
	if ( [delegate respondsToSelector: @selector(fsItemShouldIgnoreCreatorCode:)] )
		ignoreCreatorCode = [delegate fsItemShouldIgnoreCreatorCode: self];
	
	//use new optimized version of loadChilds
	[self loadChildrenAndSetKindStrings: YES ignoreCreatorCode: ignoreCreatorCode];
	
	NSLog (@"package check count: %d", g_packageCheckCount);
}

@end

//================ implementation FSItem(Private) ======================================================

@implementation FSItem(Private)

- (id) initWithName: (NSString*) name
			 parent: (FSItem*) parent
	  setKindString: (BOOL) setKindString
  ignoreCreatorCode: (BOOL) ignoreCreatorCode
			  fsRef: (FSRef*) fsRef
		catalogInfo: (FSCatalogInfo *)catalogInfo
{
    self = [super init];
	
	_type = FileFolderItem;
	
    _parent = parent;	//no retain
	
    _hash = 0;	//will be generated on demand (see FSItem.hash)
	
	
	NTFSRefObject *fsRefObject = [[NTFSRefObject alloc] initWithRef: fsRef
													   catalogInfo: catalogInfo
															bitmap: kCatalogInfoBitmapBulk
															  name: name
														 parentRef: [[parent fileDesc] fsRefObject]];
	
	_fileDesc = [[NTFileDesc alloc] initWithFSRefObject: fsRefObject];
	[fsRefObject release];
	
	BOOL isFolder = [_fileDesc isDirectory];

	if ( !isFolder )
		[self setSizeValue: catalogInfo->dataLogicalSize + catalogInfo->rsrcLogicalSize];
	
	if ( setKindString )
		[self setKindStringIgnoringCreatorCode: ignoreCreatorCode includeChilds: NO];
	
    if ( isFolder )
		g_folderCount++;
    else
        g_fileCount++;
	
    return self;
}

- (void) setParent: (FSItem*) parent
{
	_parent = parent; //weak reference (parents owns us)
	
	_hash = 0; //our hash is now invalid at it depends on the path
}

- (void) loadChildrenAndSetKindStrings: (BOOL) setKindStrings
					 ignoreCreatorCode: (BOOL) ignoreCreatorCode
{
    if ( ![self isFolder] )
        return;
	
	id delegate = [self delegate];
	
	//should we cancel the loading?
	if ( [delegate respondsToSelector: @selector(fsItemEnteringFolder:)]
		 && ![delegate fsItemEnteringFolder: self] )
	{
		[NSException raise: FSItemLoadingCanceledException format: @""];
	}
	
	[_childs release];
    _childs = [[NSMutableArray alloc] init];

    //should the kind strings of our childs should be set initially?
	if ( setKindStrings && ![self isRoot] )
	{
		if ( ![delegate respondsToSelector:@selector(fsItemShouldLookIntoPackages:)]
			|| ![delegate fsItemShouldLookIntoPackages: self] )
		{
			setKindStrings = ![self isPackage];
		}
	}
	
	NSAutoreleasePool *localAutorelasePool = nil;
	unsigned i = 0;
	
    // On each iteration of the do-while loop, retrieve kRequestCountPerIteration number of catalog infos.
	//We use the number of FSCatalogInfos that will fit in exactly four VM pages (#113).
	//This is a good balance between the iteration I/O overhead and the risk of incurring additional I/O from additional memory allocation.
    FSIterator iterator;
    OSStatus result;
	
    result = FSOpenIterator([[self fileDesc] FSRefPtr], kFSIterateFlat, &iterator);
    if (result == noErr)
	{
		while ( result == noErr )
		{
			ItemCount actualCount = 0;
				
			result = FSGetCatalogInfoBulk( iterator,
										   kRequestCountPerIteration,
										   &actualCount,
										   NULL,
										   kCatalogInfoBitmapBulk,
										   g_BulkCatalogInfo.catalogInfoArray,
										   g_BulkCatalogInfo.fsRefArray,
										   NULL,
										   g_BulkCatalogInfo.namesArray );
			
			if ( actualCount > 10 )
			{
				[localAutorelasePool release];
				localAutorelasePool = [[NSAutoreleasePool alloc] init];
			}
			
			if (result == noErr || result == errFSNoMoreItems)
			{
				for (i = 0; i < actualCount; i++)
				{
					FSItem *newChild = nil;
					
					const unichar *chars = (const unichar *) &g_BulkCatalogInfo.namesArray[i].unicode;
					unsigned length = (unsigned) g_BulkCatalogInfo.namesArray[i].length;
					
					NSString *childName = [[NSString alloc] initWithCharacters:chars length:length];
					
					NS_DURING
					{
						newChild = [[FSItem alloc] initWithName: childName
														 parent: self
												  setKindString: setKindStrings
											  ignoreCreatorCode: ignoreCreatorCode
														  fsRef: &g_BulkCatalogInfo.fsRefArray[i]
													catalogInfo: &g_BulkCatalogInfo.catalogInfoArray[i] ];
						if ( newChild != nil )
							[_childs addObject: newChild];
						else
							LOG( @"ignoring '%@' in '%@'", childName, [self path]);
					}
					NS_HANDLER
					{
						LOG( @"couldn't create FSItem for '%@' in '%@': %@ (%@)", childName, [self path], [localException reason], [localException name] );
						[newChild release];
						[childName release];
						
						[localException raise]; //Re-raise the exception
					}
					NS_ENDHANDLER
					
					[childName release];
					[newChild release];
				} //for (i = 0; i < actualCount; i++)
										
				[localAutorelasePool release];
				localAutorelasePool = nil;
					
			} //if (result == noErr || result == errFSNoMoreItems)
		} //while ( result == noErr )
				
		FSCloseIterator(iterator);
    } //if (result == noErr)
	else
	{
		LOG( @"couldn't create FSIterator for '%@': error %i", [self path], result );
		if ( result == nsvErr ) //volume has been unmounted
		{
			[NSException raise: FSItemLoadingFailedException
						format: NSLocalizedString( @"The volume has been ejected during loading of folder centents.", @"")];
		}
	}
	
	//let the new FSItems representing folders load their childs
	unsigned long long size = 0;			
	for ( i = 0; i < [_childs count]; i++ )
	{
		FSItem *child = [_childs objectAtIndex: i];
		NTFileDesc *childDesc = [child fileDesc];
		
		if ( [childDesc isDirectory] && ![childDesc isVolume] )
			[child loadChildrenAndSetKindStrings: setKindStrings ignoreCreatorCode: ignoreCreatorCode];
		
		size += [child sizeValue];
	}
	
	[self setSizeValue: size];
	
	[_childs sortUsingSelector: @selector(compareSizeDescendingly:)];
	
	[localAutorelasePool release];
	
	//should we cancel the loading?
	if ( [delegate respondsToSelector: @selector(fsItemExittingFolder:)]
		 && ![delegate fsItemExittingFolder: self] )
	{
		[NSException raise: FSItemLoadingCanceledException format: @""];
	}
}

//compare the size of 2 FSItems
- (NSComparisonResult) compareSizeDescendingly: (FSItem*) other
{
	//if just one of the 2 FSItems (self xor other) is a special item, then the special item is considered to be
	//smaller (so the special items are at the end of the child array)
	if ( [self isSpecialItem] ^ [other isSpecialItem] )
		return NSOrderedDescending;
		
	UInt64 mySize = [self sizeValue];
	UInt64 otherSize = [other sizeValue];
	
	//we want the sorting to be descending
	if ( mySize < otherSize )
		return NSOrderedDescending;
	if ( mySize > otherSize )
		return NSOrderedAscending;

	//if both FSItems have the same size, order by their names
	return [[self name] compare: [other name] options: NSNumericSearch];
}

- (void) setSize: (NSNumber*) newSize
{
	NSParameterAssert( newSize != nil );
	
	if ( _size != newSize )
	{
		[_size release];
		_size = [newSize retain];
	}
}

- (void) setSizeValue: (unsigned long long) newSize
{
	//NTFileDesc keeps the size as a number and FSItems as a NSNumber object for key-value-coding
	//(if this is a special item, we don't set the size in our NTFileDesc object, as this
	//points to the root's NTFileDesc! (see FSItem.fileDesc))
	if ( ![self isSpecialItem] )
	{
		[[self fileDesc] setSize: newSize];
		[_size release];
		_size = nil;
	}
	else
	{
		NSNumber *size = [[NSNumber alloc] initWithUnsignedLongLong: newSize];
		[self setSize: size];
		[size release];
	}
}

@end


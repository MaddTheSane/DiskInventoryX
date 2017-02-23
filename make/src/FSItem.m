//
//  FSItem.m
//  DiskAccountant
//
//  Created by Doom on Mon Sep 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "FSItem.h"

unsigned g_fileCount;
unsigned g_folderCount;

NSString* FSItemEnteringFolder = @"NotificationEnterinfFolder";
NSString* FSItemTheFolder = @"TheEnteredFolder";

//we use a global variable for our notifications user info (otherwise a new one must be allocated each time)
NSMutableDictionary *g_notificationUserInfo = nil;

//================ interface FSItem(Private) ======================================================

@interface FSItem(Private)

- (NSComparisonResult) compareSize: (FSItem*) other; //compares sizes
- (BOOL) loadProperties;
- (BOOL) refreshFSRef;

@end

//================ implementation FSItem ======================================================

@implementation FSItem

- (id) initWithName: (NSString *) name parent: (FSItem*) parent
{
    self = [super init];
    
	//instantiated the dictionary for our notifications user info
    if( g_notificationUserInfo == nil )
        g_notificationUserInfo = [[NSMutableDictionary alloc] init];
    
    _name = [name retain];
    _folderName = nil; //only valid for the root item
    
    _parent = parent;	//no retain

    if ( ![self loadProperties] )
    {
        [self release];
        return nil;
    }

    if ( [self isFolder] )
         g_folderCount++;
    else
        g_fileCount++;

    return self;
}

- (id) initWithPath: (NSString *) path
{
    self = [super init];

    if( g_notificationUserInfo == nil )
        g_notificationUserInfo = [[NSMutableDictionary alloc] init];
    
    g_fileCount = 0;
    g_folderCount = 0;

    _name = [[path lastPathComponent] retain];
    _folderName = [[path stringByDeletingLastPathComponent] retain];

    _parent = nil; //we are the root item

    if ( ![self loadProperties] )
    {
        [self release];
        return nil;
    }

    NSAssert1( [self isFolder], @"root item is no directory: %@", path );
    
    return self;
}

- (void) dealloc
{
    [_childs release];
    
    [_name release];
    [_kindName release];
    [_folderName release];	//only != nil for root item
    [_hashObject release];
    [_displayName release];
    
    //_parent no release!

    [super dealloc];
}

- (unsigned) hash
{
    return _hash;
}

- (id) hashObject
{
    if ( _hashObject == nil )
    {
//        _hashObject = [NSString stringWithFormat: @"%u", [self hash]];
        _hashObject = [NSNumber numberWithUnsignedLong: [self hash]];
        [_hashObject retain];
    }

    return _hashObject;
    
    //return [NSNumber numberWithUnsignedLong: [self hash]];
}

- (BOOL) isEqual: (id) object
{
    FSItem *item = object;
    return [item isKindOfClass: [FSItem class]] && memcmp( &_fsRef, &item->_fsRef, sizeof(_fsRef) ) == 0;
}

- (NSString *) description
{
    return [self path];
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
    return _isFolder;
}

- (BOOL) isPackage
{
    return _isPackage;
}

- (NSEnumerator *) childEnumerator
{
    return [_childs objectEnumerator];
}

- (FSItem*) childAtIndex: (unsigned) index
{
    return [_childs objectAtIndex: index];
}

- (unsigned) childCount
{
    return [_childs count];
}

- (void) removeChild: (FSItem*) child
{
	unsigned index = [_childs indexOfObjectIdenticalTo: child];
	if ( index != NSNotFound )
	{
		_size -= [child size];
		[_childs removeObjectAtIndex: index];
	}
}

- (unsigned long long) size
{
    return _size;
}

- (NSString *) displaySize
{
    double dsize = [self size];

    NSString* units[] = {@"Bytes", @"kB", @"MB", @"GB", @"TB"};

    unsigned i = 0;
    while ( dsize >= 1024 && i < 5 )
    {
        i++;
        
        dsize /= 1024;
    }

    if ( i <= 1 )
		//Bytes
        return [NSString stringWithFormat: @"%u %@", (unsigned) round(dsize), units[i] ];
    else
    {
		//kB, MB, GB or TB
        //return [NSString stringWithFormat: @"%.1f %@", (float) dsize, units[i]];
        NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        
        [numberFormatter setLocalizesFormat: YES];
        [numberFormatter setFormat:@"#,#0.0"];
        
        return [NSString stringWithFormat: @"%@ %@", [numberFormatter stringForObjectValue: [NSNumber numberWithDouble: dsize]], units[i]];
    }
}

- (NSString *) name
{
    return _name;
}

- (NSString *) path
{
    //folder + "/" + name
    return [[self folderName] stringByAppendingPathComponent: [self name]];
}

- (NSString *) folderName
{
    if ( ![self isRoot] )
        return [_parent path];
    else
        return _folderName;
}

//display string for name (with or without extension; localized file names)
- (NSString *) displayName
{
    if ( _displayName == nil )
    {
        //Carbon:
        //Carbon calls always return retained objects!
		if ( LSCopyDisplayNameForRef( [self fsRef], (CFStringRef*) &_displayName ) != 0 )
		{
			//LSCopyDisplayNameForRef failed; maybe because our FSRef is out of date
			if ( [self refreshFSRef] )
			{
				//one retry
				if ( LSCopyDisplayNameForRef( [self fsRef], (CFStringRef*) &_displayName ) == 0 )
				{
					//gotcha, it worked!
				}
			}
		}
		
		if ( _displayName == nil )
		{
            LOG( @"couldn't get display name for '%@'; will use file name", [self path] );
			//we need to copy the string, as we will release both in "dealloc"
			_displayName = [[self name] copy];
		}
		
		
        //Cocoa:
        //_displayName = [[NSFileManager defaultManager] displayNameAtPath: [self path]];
        //[_displayName retain];
    }

    return _displayName;
}

- (NSString *) displayFolderName
{
    if ( _parent != nil )
        return [[_parent displayFolderName] stringByAppendingPathComponent: [_parent displayName]];
    else
        return [NSString string];
}

//get display string for kind ("Application", "Simple Text Document", ...)
- (NSString *) kindName
{
    if ( _kindName == nil )
    {
		if ( LSCopyKindStringForRef( [self fsRef], (CFStringRef*) &_kindName) != 0 )
		{
			//LSCopyKindStringForRef failed; maybe because our FSRef is out of date
			if ( [self refreshFSRef] )
			{
				//one retry
				if ( LSCopyKindStringForRef( [self fsRef], (CFStringRef*) &_kindName) == 0 )
				{
					//gotcha, it worked!
				}
			}
		}
		
		if ( _kindName == nil )
		{
			LOG( @"couldn't get kind name for '%@'; will use default kind", [self path]);
			_kindName = @"Document";
		}
    }

    return _kindName;
}

- (const FSRefPtr) fsRef 
{
    return &_fsRef;
}

//if this is a folder, load all containing files (recursively)
- (void) loadChilds
{
    if ( ![self isFolder] )
        return;
    
	LOG( @"entering folder '%@'", [self path] );
	
    [g_notificationUserInfo setObject: self forKey: FSItemTheFolder];
    [[NSNotificationCenter defaultCenter] postNotificationName: FSItemEnteringFolder object: [self root] userInfo: g_notificationUserInfo];
    
    NSAutoreleasePool *localAutorelasePool = [[NSAutoreleasePool alloc] init];
    
    _childs = [[NSMutableArray alloc] init];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *contents = [fm directoryContentsAtPath: [self path]];
    
    NSString *folder = [self path];
    
    NSEnumerator *enumerator = [contents objectEnumerator];
    NSString *fileName;
    _size = 0;
    while ( ( fileName = [enumerator nextObject] ) != NULL )
    {
        FSItem *newChild = nil;
        
        NS_DURING
            newChild = [[FSItem alloc] initWithName: fileName parent: self];
            if ( newChild != nil )
            {
                [newChild loadChilds];
                
                _size += [newChild size];
                
                [_childs addObject: newChild];
            }
            else
                LOG( @"ignoring '%@' in '%@'", fileName, folder );
        NS_HANDLER
            LOG( @"couldn't create FSItem for '%@' in '%@': %@ (%@)", fileName, folder, [localException reason], [localException name] );
            [newChild release];
        NS_ENDHANDLER
        
        [newChild release];
    }
    
    [_childs sortUsingSelector: @selector(compareSize:)];
    
    [localAutorelasePool release];
}

@end

//================ implementation FSItem(Private) ======================================================

@implementation FSItem(Private)

//load the needes file information (size etc.)
- (BOOL) loadProperties
{
    NSString *path = [self path];

    _hash = [path hash];

    //get file reference for path
    if ( FSPathMakeRef( [path fileSystemRepresentation], &_fsRef, NULL ) != 0 )
        return FALSE;	//not a real file/folder

    NSDictionary *attribs = [[NSFileManager defaultManager] fileAttributesAtPath: path traverseLink: NO];
    NSAssert1( attribs != NULL, @"could not get file attributes for '%@'", path );

    NSString *type = [attribs fileType];
    _isFolder = [type isEqualToString: NSFileTypeDirectory];

    //we are only looking for 'real' files and folders (no symbolic links)
    if ( !_isFolder && ![type isEqualToString: NSFileTypeRegular] )
        return NO;

    //package?
    _isPackage = _isFolder && [[NSWorkspace sharedWorkspace] isFilePackageAtPath: [self path]];

    FSCatalogInfoBitmap CatalogInfoToRetrieve = 0;

    //if the NSFileManager says this is a folder, it can be a Volume (mostly in "/Volumes/" or the root "/")
    if ( _isFolder )
        //we ignore mounted volumes that are not the root of the file system part we're examining
        CatalogInfoToRetrieve |= [self isRoot] ? 0 : kFSCatInfoParentDirID;
    else
        CatalogInfoToRetrieve |= (kFSCatInfoDataSizes | kFSCatInfoRsrcSizes); //get file's resource and data folk sizes

    if ( CatalogInfoToRetrieve != 0 )
    {
        FSCatalogInfo catalogInfo;
        if ( FSGetCatalogInfo ( &_fsRef, CatalogInfoToRetrieve, &catalogInfo, nil, nil, nil ) != 0 )
		{
            LOG( @"could not get catalog info for '%@'", path);
			catalogInfo.dataLogicalSize = catalogInfo.rsrcLogicalSize = 0;
		}
		else
		{
			if ( _isFolder && catalogInfo.parentDirID == fsRtParID )
				return NO; //this is a Volume!
		}

        //size
        _size = _isFolder ? 0 : ( catalogInfo.dataLogicalSize + catalogInfo.rsrcLogicalSize );
    }

    return TRUE;
}

//re-load the file reference (FSRef) 
- (BOOL) refreshFSRef
{
	if ( FSPathMakeRef( [[self path] fileSystemRepresentation], &_fsRef, NULL ) != 0 )
	{
		memset( &_fsRef, sizeof(_fsRef), 0 );
		return NO;
	}
	else
		return YES;
}

//compare the size of 2 FSItems
- (NSComparisonResult) compareSize: (FSItem*) other
{
    if ( [self size] == [other size] )
        return NSOrderedSame;
    else
        return [self size] > [other size] ? NSOrderedAscending : NSOrderedDescending ;
}

@end


//
//  MyDocument.m
//  Disk Accountant
//
//  Created by Doom on Wed Oct 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "FileSystemDoc.h"
#import "FileTypeColors.h"
#import "MainWindowController.h"

//============ implementation FileKindStatistic ==========================================================

@implementation FileKindStatistic

NSString *_kindName;
unsigned _fileCount;
unsigned long long _filesSize;

- (id) initWithItem: (FSItem*) item
{
    self = [super init];
    
    _kindName = [item kindName];
    [_kindName retain];

    _fileCount = 1;
    _filesSize = [item size];

    return self;
}

- (void) addItemToStatistic: (FSItem* )item;
{
    _fileCount++;
    _filesSize += [item size];
}

- (NSString*) description
{
    return [[self kindName] stringByAppendingFormat: @" {%u files; %.1f kB}", _fileCount, (float) (((double) _filesSize)/1024)]; 
}

- (NSString*) kindName
{
    return _kindName;
}

//# of files of this kind
- (unsigned) fileCount
{
    return _fileCount;
}

//sum of sizes of files of this kind
- (unsigned long long) filesSize
{
    return _filesSize;
}

@end

//============ interface FileSystemDoc(Private) ==========================================================

@interface FileSystemDoc(Private)

- (void) collectFileKindStatistics: (FSItem*) parentItem;
- (void) reserveColorsForLargestKinds;
- (void) onFolderEntered: (NSNotification*) notification;

@end

//=========== implementation FileSystemDoc ==========================================================

NSString *GlobalSelectionChangedNotification = @"GlobalSelectionChanged";
NSString *ZoomedItemChangedNotification = @"ZoomedItemChanged";
NSString *ShowPackageContentsChangedNotification = @"ShowPackageContentsChanged";
NSString *FSItemsChanged = @"FSItemsChanged";

@implementation FileSystemDoc

- (id)init
{
    self = [super init];
    if ( self != nil )
    {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        _showPackageContents = FALSE;

        _zoomStack = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];        

    [_rootItem release];
    [_fileKindStatistics release];
    [_zoomStack release];

    [super dealloc];
}

- (void) makeWindowControllers
{
    // Override method to instantiate controllers for multiple document windows.
    MainWindowController *controller = [[MainWindowController alloc] initWithWindowNibName: [self windowNibName]];
    [self addWindowController:controller];
    [controller release];
}


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"TreeMap";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (BOOL) readFromFile: (NSString *) folder ofType: (NSString *) docType
{
    //load Nib with panel with progress indicator
    [NSBundle loadNibNamed: @"LoadingPanel" owner: self];

    [_loadingPanel makeKeyAndOrderFront: self];

    //display the panel and start the progress indicator
    [_loadingPanel display];

    [_loadingProgressIndicator setUsesThreadedAnimation: YES];
    [_loadingProgressIndicator startAnimation: self];

    //now the real work: loading the folder contents
    
    NS_DURING
        _rootItem = [[FSItem alloc] initWithPath: folder];

        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onFolderEntered:) name: FSItemEnteringFolder object: nil];        

        [_rootItem loadChilds];
        
        LOG(@"************** Loading complete *******************" );
        LOG(@"%u items created", g_fileCount + g_folderCount );
        LOG(@"%u files", g_fileCount );
        LOG(@"%u folders", g_folderCount );
        
		//ok, now we've got an FSItem for every file and directory in the given folder
		
		[_loadingTextField setStringValue: NSLocalizedString( @"Classifying Files", @"")];
		[[NSRunLoop currentRunLoop] runMode: NSModalPanelRunLoopMode beforeDate: [NSDate date]];
				
		//collect sizes and file count of all file kinds 
		[self refreshFileKindStatistics];
		
    NS_HANDLER
        LOG( @"error '%@' occured during directory traversal: %@", [localException name], [localException reason] );
        
        [_loadingPanel close];
		
        return NO;
    NS_ENDHANDLER

    [_loadingPanel close];
        
    return YES;
}

- (BOOL) showPackageContents
{
    return _showPackageContents;
}

- (void) setShowPackageContents: (BOOL) show
{
    show = (show == 0) ? NO : YES;
    if ( show != _showPackageContents )
    {
        _showPackageContents = show;

        //the file kind statistic should only cover the currently visible part of the file system tree
        //(this depends on the zoomed item and wether package contents is shown or not)
        [self collectFileKindStatistics: nil];
		
		FSItem* selectedItem = [self selectedItem];
		
		//invalidate current selection, as the selection might be an item in a package
		//(if "show package content" is turned off, files in packages aren't visible any more)
		if ( ![self showPackageContents] && selectedItem != nil )
		{
			[self setSelectedItem: nil];
			[[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: self userInfo: nil];
		}
        
        [[NSNotificationCenter defaultCenter] postNotificationName: ShowPackageContentsChangedNotification object: self];

        //if "show package contents" is turned off, check if selection is within a package
        //(as the selection got invalid)
        if ( ![self showPackageContents] && selectedItem != nil)
        {
            //select it's farest parent which is a package
            FSItem *packageItem = nil;
            FSItem *parentItem = [selectedItem parent];
            while ( parentItem != nil && parentItem != [self zoomedItem] )
            {
                if ( [parentItem isPackage] )
                    packageItem = parentItem;
                parentItem = [parentItem parent];
            }
			
			selectedItem = packageItem;
        }
		
		//restore selection
		if ( ![self showPackageContents] && selectedItem != nil )
		{
			[self setSelectedItem: selectedItem];
			[[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: self userInfo: nil];
		}		
    }
}

//helper methods; returns YES/NO for packages in dependency of the showPackageContents-Flag
- (BOOL) itemIsNode: (FSItem*) item
{
    //the zoomed item is always a node, even if it is a package and "show package contents" is turned off
    //(you can always zoom into packages)
    if ( item == [self zoomedItem] )
        return YES;
    
    if ( [self showPackageContents] )
        return [item isFolder];
    else
        return [item isFolder] && ![item isPackage];
}

- (FSItem*) rootItem;
{
    return _rootItem;
}

- (void) removeItem: (FSItem*) item
{
	NSParameterAssert( item != nil && item != [self zoomedItem] );

	//if the selected item should be removed, invalidate our selection
	if ( [self selectedItem] == item )
	{
		[self setSelectedItem: nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: self userInfo: nil];
	}
	
	//now remove the item from the parent's list
	FSItem *parent = [item parent];
	NSAssert( parent != nil, @"root item shouldn't be deletable" );
	
	[parent removeChild: item];
	
	//update our file kind statistics
	[self refreshFileKindStatistics];
	
	//notify observers of the change
	[[NSNotificationCenter defaultCenter] postNotificationName: FSItemsChanged object: self userInfo: nil];
}

- (FSItem*) zoomedItem
{
    return [_zoomStack count] == 0 ? [self rootItem] : [_zoomStack lastObject];
}

- (void) zoomIntoItem: (FSItem*) item
{
    if ( [_zoomStack count] > 0 && item == [_zoomStack lastObject] )
        return;
    
    //reset selection as the currently selected item might not be a child of the item to zoom in
    [self setSelectedItem: nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: self userInfo: nil];

    [_zoomStack addObject: item];
    
    //the file kind statistic should only cover the currently visible part of the file system tree
    //(this depends on the zoomed item and wether package contents is shown or not)
    [self collectFileKindStatistics: nil];

    [[NSNotificationCenter defaultCenter] postNotificationName: ZoomedItemChangedNotification object: self];
}

- (void) zoomOutOneStep
{
    if ( [_zoomStack count] > 0 )
    {
        [_zoomStack removeLastObject];
        
        //the file kind statistic should only cover the currently visible part of the file system tree
        //(this depends on the zoomed item and wether package contents is shown or not)
        [self collectFileKindStatistics: nil];

        [[NSNotificationCenter defaultCenter] postNotificationName: ZoomedItemChangedNotification object: self];
    }
}

- (void) zoomOutToItem: (FSItem*) item
{
    NSAssert( [_zoomStack count] > 0, @"can't zoom out if zoom stack is empty" );
    
    NSParameterAssert( item == nil
                       || item == [self rootItem]
                       || [_zoomStack indexOfObjectIdenticalTo: item] != NSNotFound );
    
    if ( item == nil || item == [self rootItem] )
    {
        [_zoomStack removeAllObjects];
    }
    else if ( [_zoomStack count] == 1 )
    {
        NSAssert( item == [_zoomStack lastObject], @"zoom error");
        [_zoomStack removeAllObjects];
    }
    else
    {
        unsigned itemIndex = [_zoomStack indexOfObjectIdenticalTo: item];
        if ( itemIndex != NSNotFound )
        {
            unsigned itemsToRemove = [_zoomStack count] - itemIndex - 1;
            for ( ; itemsToRemove > 0; itemsToRemove-- )
                [_zoomStack removeLastObject];
        }
        
    }
    
    //the file kind statistic should only cover the currently visible part of the file system tree
    //(this depends on the zoomed item and wether package contents is shown or not)
    [self collectFileKindStatistics: nil];

    [[NSNotificationCenter defaultCenter] postNotificationName: ZoomedItemChangedNotification object: self];
}

- (FSItem*) selectedItem
{
    return _selectedItem;
}

- (void) setSelectedItem: (FSItem*) item
{
    if ( _selectedItem == item )
        return;

    _selectedItem = item;

    //post notification
//    [[NSNotificationCenter defaultCenter] postNotificationName: GlobalSelectionChangedNotification object: self userInfo: nil];
    
}

- (NSString *)fileName
{
    //we should override this method so the window controller will display
    //the icon of the currently zoomed item (or of the root item) in the window's title bar
    return [[self zoomedItem] path];
}

- (NSString *)displayName
{
    NSString *displayName = [[self zoomedItem] displayName];

    displayName = [displayName stringByAppendingFormat: @" (%@)", [[self zoomedItem] displaySize]];

    return displayName;
}

- (NSDictionary*) kindStatistics
{
    NSAssert( _fileKindStatistics != nil, @"kind statistics aren't collected yet" );

    return _fileKindStatistics;
}

- (FileKindStatistic*) kindStatisticForItem: (FSItem*) item
{
    return [self kindStatisticForKind: [item kindName]];
}

- (FileKindStatistic*) kindStatisticForKind: (NSString*) kindName
{
    return [[self kindStatistics] objectForKey: kindName];
}

- (void) refreshFileKindStatistics
{
	//collect sizes and file count of all file kinds 
	[self collectFileKindStatistics: nil];
	
	//reserve the predefined colors for the kinds with the biggest size sums of the appropriate files
	[self reserveColorsForLargestKinds];
}

@end

//================ implementation FileSystemDoc(Private) ======================================================

//compares 2 FileKindStatistic objects by their sizes; the objects are identified by their kind names
int CompareKindStatisticsIdentifiedByNames( id fs1, id fs2, void *context )
{
    FileSystemDoc *doc = context;

    //get FileKindStatistic objects by kind names
    fs1 = [doc kindStatisticForKind: fs1];
    fs2 = [doc kindStatisticForKind: fs2];

    if ( [fs1 filesSize] == [fs2 filesSize] )
        return NSOrderedSame;
    else
        return [fs1 filesSize] > [fs2 filesSize] ? NSOrderedAscending : NSOrderedDescending ;
}

@implementation FileSystemDoc(Private)

- (void) collectFileKindStatistics: (FSItem*) item
{
    //if we are called with nil as item, this is the first call of this method
    //so initialize our kinds dictionary
    if ( item == nil )
    {
        if ( _fileKindStatistics == nil )
            _fileKindStatistics = [[NSMutableDictionary alloc] init];
        else
            [_fileKindStatistics removeAllObjects];
        
        item = [self zoomedItem];
    }

    //if the item is a folder, recurse through it's childs
    if ( [self itemIsNode: item] )
    {
        unsigned i;
        for ( i = 0; i < [item childCount]; i++ )
            [self collectFileKindStatistics: [item childAtIndex: i]];
    }
    else
    {
        //item is a file, so add it's informations to the appropriate statistic object
        FileKindStatistic* kindStatistic = [self kindStatisticForItem: item];
        if ( kindStatistic == nil )
        {
            //we don't have a statistic object for the item's kind yet, so create one
            kindStatistic = [[FileKindStatistic alloc] initWithItem: item];
            [_fileKindStatistics setObject: kindStatistic forKey: [item kindName]];
            [kindStatistic release];
        }
        else
            [kindStatistic addItemToStatistic: item];
    }
}

- (void) reserveColorsForLargestKinds
{
    NSMutableArray *kinds = [[[self kindStatistics] allKeys] mutableCopy];

    //order Statistics descendantly by size
    [kinds sortUsingFunction: &CompareKindStatisticsIdentifiedByNames context: self];

    NSEnumerator *kindNameEnum = [kinds objectEnumerator];
    NSString *kindName;
    while ( ( kindName = [kindNameEnum nextObject] ) != nil )
    {
        [[FileTypeColors instance] colorForKind: kindName];
    }
}

- (void) onFolderEntered: (NSNotification*) notification
{
    FSItem *item = [[notification userInfo] objectForKey: FSItemTheFolder];
    NSParameterAssert( item != nil );
    
    FSItem* parentItem = [item parent];
	
	//we display only folders 5 levels deep and we don't go into packages
    unsigned i;
    for ( i = 1; i < 5 && parentItem != nil && ![parentItem isPackage]; i++ )
        parentItem = [parentItem parent];
    
    if ( parentItem == nil )
    {
        NSString *path = [item displayFolderName];
        path = [path stringByAppendingPathComponent: [item displayName]];
        
        [_loadingTextField setStringValue: path];
    }
    
	NSDate *now = [NSDate date];
	[[NSRunLoop currentRunLoop] runMode: NSModalPanelRunLoopMode beforeDate: now];
}

@end


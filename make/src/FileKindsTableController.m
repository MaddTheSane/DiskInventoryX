//
//  FSItem.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//  Copyright (c) 2003 Tjark Derlien. All rights reserved.
//

#import "FileKindsTableController.h"
#import "FileTypeColors.h"
#import <TreeMapView/TMVCushionRenderer.h>
#import <TreeMapView/NSBitmapImageRep-CreationExtensions.h>
#import "Preferences.h"
#import "MainWindowController.h"

//============ interface FileKindsTableController(Private) ==========================================================

@interface FileKindsTableController(Private)

- (void) reloadData;
- (void) createKindArray;
- (NSImage*) colorImageForRow: (int) row column: (NSTableColumn*) column;
- (void) setTableViewFont;
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
@end

//============ implementation FileKindsTableController ==========================================================

@implementation FileKindsTableController

- (void) awakeFromNib
{
	FileSystemDoc *doc = [self document];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
    [center addObserver: self
			   selector: @selector(globalSelectionChanged:)
				   name: GlobalSelectionChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(zoomedItemChanged:)
				   name: ZoomedItemChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(viewOptionChanged:)
				   name: ViewOptionChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(itemsChanged:)
				   name: FSItemsChangedNotification
				 object: doc];
	
    [center addObserver: self
			   selector: @selector(windowWillClose:)
				   name: NSWindowWillCloseNotification
				 object: [[_tableView window] parentWindow]];
	
	//this will alloc Objects for kind array and cushion images
    [self createKindArray];

	//set formatter for size column
	FileSizeFormatter *sizeFormatter = [[[FileSizeFormatter alloc] init] autorelease];
	[[[_tableView tableColumnWithIdentifier: @"size"] dataCell] setFormatter: sizeFormatter];
	
	//set up KVO
	[[NSUserDefaults standardUserDefaults] addObserver: self
											forKeyPath: UseSmallFontInKindStatistic
											   options: NSKeyValueChangeSetting
											   context: nil];
	
	//set small font for all for all columns if needed
	[self setTableViewFont];
    
    [_tableView reloadData];
}

- (void) dealloc
{    
    [_kinds release];
    [_cushionImages release];

    [super dealloc];
}

- (FileSystemDoc*) document
{
    if ( _document == nil )
        _document = [_windowController document];

    return _document;
}

#pragma mark --------NSTableView delegate methods-----------------

//NSTableView delegate
- (void) tableView: (NSTableView*) tableView willDisplayCell: (id) cell forTableColumn: (NSTableColumn*) tableColumn row: (int) row
{
}

#pragma mark --------NSTableView data source methods-----------------

//NSTableView data source
- (int) numberOfRowsInTableView: (NSTableView*) view
{
    return (int) [_kinds count];
}

- (id) tableView:  (NSTableView*) tableView objectValueForTableColumn: (NSTableColumn*) tableColumn row: (int) row
{
    NSString *columnTag = [tableColumn identifier];
	
	if ( [columnTag isEqualToString: @"color"] )
	{
		return [self colorImageForRow: row column: tableColumn];
	}
	else
	{
		//name, file count or size
		FileKindStatistic *kindStatistics = [_kinds objectAtIndex: row];
		return [kindStatistics valueForKey: columnTag];
	}
}

#pragma mark --------NSTableView notifications-----------------

- (void) tableViewSelectionDidChange: (NSNotification *) aNotification
{
    //int row = [_tableView selectedRow];
}

@end

//============ implementation FileKindsTableController(Private) ===============================================

@implementation FileKindsTableController(Private)

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	if ( object == [NSUserDefaults standardUserDefaults] )
	{
		if ( [keyPath isEqualToString: UseSmallFontInKindStatistic] )
			[self setTableViewFont];
	}
}

static NSInteger CompareFileStatistics( id fs1, id fs2, void *context )
{
    FileKindStatistic *stat1 = (FileKindStatistic*) fs1;
	FileKindStatistic *stat2 = (FileKindStatistic*) fs2;
	
	//we want the sorting to be descending, so flip the result of [NSNumber compare:]
    switch ([[stat1 size] compare: [stat2 size]])
	{
		case NSOrderedSame: return NSOrderedSame;
		case NSOrderedAscending: return NSOrderedDescending;
		case NSOrderedDescending: return NSOrderedAscending;
	}
	
	NSCAssert( NO, @"illegal return value of [NSNumber compare:]" );	
	return NSOrderedSame;
}

- (void) createKindArray
{
    FileSystemDoc *document = [self document];
	
	unsigned statisticsCount = [[document kindStatistics] count];
	
    [_kinds release];
    _kinds = [[NSMutableArray alloc] initWithCapacity: statisticsCount];
	
	[_cushionImages release];
    _cushionImages = [[NSMutableArray alloc] initWithCapacity: statisticsCount];

    NSEnumerator *kindEnum = [[document kindStatistics] objectEnumerator];

    FileKindStatistic *statistic;
    while ( ( statistic = [kindEnum nextObject] ) != nil )
    {
        [_kinds addObject: statistic];
		//fill our image array (for column "color") with NSNulls
		//(images will be created on demand in "colorImageForRow:")
		[_cushionImages addObject: [NSNull null]];
    }

    [_kinds sortUsingFunction: &CompareFileStatistics context: NULL];
}

//returns a cushion image for a given row in the tableview
- (NSImage*) colorImageForRow: (int) row column: (NSTableColumn*) column
{
	NSImage *image = [_cushionImages objectAtIndex: row];
	
	NSSize cellSize = NSMakeSize( [column width], [_tableView rowHeight] );
	
	//if we don't have any image for that row yet or the cell size has changed, create a new image
	if ( image == (NSImage*) [NSNull null] || !NSEqualSizes( [image size], cellSize ) )
	{
		//create a Bitmap with 24 bit color depth and no alpha component							 
		NSBitmapImageRep* bitmap = [[ NSBitmapImageRep alloc]
										initRGBBitmapWithWidth: cellSize.width height: cellSize.height];
		
		//..and draw a cushion in that bitmap
		TMVCushionRenderer *cushionRenderer = [[TMVCushionRenderer alloc] initWithRect: NSMakeRect(0, 0, cellSize.width, cellSize.height)];
		
		FileKindStatistic *kindStatistics = [_kinds objectAtIndex: row];
		[cushionRenderer setColor: [[FileTypeColors instance] colorForKind: [kindStatistics kindName]]];
		
		[cushionRenderer addRidgeByHeightFactor: 0.5];
		[cushionRenderer renderCushionInBitmap: bitmap];
		
		[cushionRenderer release];
		
		//put an image with the cushion in the _cushionImages array for the next time this row is about to be drawn
		image = [bitmap suitableImageForView: _tableView];
		[bitmap release];
		
		[_cushionImages replaceObjectAtIndex: row withObject: image];
	}

	return image;
}

- (void) setTableViewFont
{
	float fontSize = 0;
	if ( [[NSUserDefaults standardUserDefaults] boolForKey: UseSmallFontInKindStatistic] )
		fontSize = [NSFont smallSystemFontSize];
	else
		fontSize = [NSFont systemFontSize];
	
	NSFont *font = [NSFont systemFontOfSize: fontSize];

	NSEnumerator *columnEnum = [[_tableView tableColumns] objectEnumerator];
	NSTableColumn *column;
	while ( (column = [columnEnum nextObject]) != nil )
	{
		NSCell *cell = [column dataCell];
		if ( [cell type] == NSTextCellType )
			[cell setFont: font];
	}
	
	[_tableView setRowHeight: fontSize +4];
}

- (void) reloadData
{
    [self createKindArray];
    
    [_tableView reloadData];
}

#pragma mark --------document notifications-----------------

- (void) globalSelectionChanged: (NSNotification*) notification
{
    FSItem *item = [[self document] selectedItem];

    if ( item != nil )
    {
        NSString *itemKind = [item kindName];
		
		//find the corresponding FileKindStatistic-Object and select it
        NSUInteger i;
        for ( i = 0; i < [_kinds count]; i++ )
        {
			FileKindStatistic* statistic = [_kinds objectAtIndex: i];
            if ( [itemKind isEqualToString: [statistic kindName]] )
            {
                [_tableView selectRowIndexes: [NSIndexSet indexSetWithIndex:i] byExtendingSelection: NO];
                [_tableView scrollRowToVisible: i];
                return;
            }
        }
    }

    //unknown kind (maybe a folder)
    [_tableView deselectAll: self];
}

- (void) zoomedItemChanged: (NSNotification*) notification
{
    [self reloadData];
}

- (void) viewOptionChanged: (NSNotification*) notification
{
	NSString *theOption = [[notification userInfo] objectForKey:ChangedViewOption];
	
	if ( [theOption isEqualToString: ShowPackageContents]
		 || [theOption isEqualToString: ShowPhysicalFileSize]
		 || [theOption isEqualToString: IgnoreCreatorCode] )
	{
		[self reloadData];
	}
}

- (void) itemsChanged: (NSNotification*) notification
{
    [self reloadData];
	[self globalSelectionChanged: nil];
}

#pragma mark --------window notifications-----------------

- (void) windowWillClose: (NSNotification*) notification
{
	[[NSUserDefaults standardUserDefaults] removeObserver: self forKeyPath: UseSmallFontInKindStatistic];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end

